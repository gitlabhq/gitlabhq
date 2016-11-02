# Limit conflicts with EE when developing on CE

This guide contains best-practices for avoiding conflicts between CE and EE.

## Context

Usually, GitLab Community Edition is merged into the Enterprise Edition once a
week. During these merges, it's very common to get conflicts when some changes
in CE do not apply cleanly to EE.

In this document, we will list the best practices to avoid such conflicts or to
make them easily solvable by the person who does the CE->EE merge.

## Different type of conflicts

### Models

#### Common issues

TODO

#### Mitigations

TODO

### Services

#### Common issues

TODO

#### Mitigations

TODO

### Controllers

#### Common issues

In controllers, the most common type of conflicts is either in a `before_action`
that has a list of actions in CE but EE adds some actions to that list.

Same problems often occurs for `params.require` / `params.permit` calls.

Other conflicts usually involve specific code for EE-specific features such as:

- LDAP:
    ```diff
        def destroy
          @key = current_user.keys.find(params[:id])
     -    @key.destroy
     +    @key.destroy unless @key.is_a? LDAPKey

          respond_to do |format|
    ```
- Geo:
    ```diff
    def after_sign_out_path_for(resource)
    -    current_application_settings.after_sign_out_path.presence || new_user_session_path
    +    if Gitlab::Geo.secondary?
    +      Gitlab::Geo.primary_node.oauth_logout_url(@geo_logout_state)
    +    else
    +      current_application_settings.after_sign_out_path.presence || new_user_session_path
    +    end
    end
    ```
- Audit log:
    ```diff
    def approve_access_request
    -    Members::ApproveAccessRequestService.new(membershipable, current_user, params).execute
    +    member = Members::ApproveAccessRequestService.new(membershipable, current_user, params).execute
    +
    +    log_audit_event(member, action: :create)

      redirect_to polymorphic_url([membershipable, :members])
    end
    ```

#### Mitigations

Separate CE and EE actions/keywords. For instance for `params.require` in
`ProjectsController`:

```ruby
def project_params
  params.require(:project).permit(project_params_ce)
  # On EE, this is always:
  # params.require(:project).permit(project_params_ce + project_params_ee)
end

# Always returns an array of symbols, created however best fits the use case.
# It _should_ be sorted alphabetically.
def project_params_ce
  %i[
    description
    name
    path
  ]
end

# (On EE)
def project_params_ee
  %i[
    approvals_before_merge
    approver_group_ids
    approver_ids
    ...
  ]
end
```

### Views

#### Common issues

A few issues often happen here:

1. Indentation issue
1. A block of code added in CE conflicts because there is already another block
  at the same place in EE

#### Mitigations

Blocks of code that are EE-specific should be moved to partials as much as
possible to avoid conflicts with big chunks of HAML code that that are not funny
to resolve when you add the indentation in the equation.

For instance this kind of things:

```haml
- if can?(current_user, :"admin_#{issuable.to_ability_name}", issuable.project)
  - has_due_date = issuable.has_attribute?(:due_date)
  %hr
  .row
    %div{ class: (has_due_date ? "col-lg-6" : "col-sm-12") }
      .form-group.issue-assignee
        = f.label :assignee_id, "Assignee", class: "control-label #{"col-lg-4" if has_due_date}"
        .col-sm-10{ class: ("col-lg-8" if has_due_date) }
          .issuable-form-select-holder
            - if issuable.assignee_id
              = f.hidden_field :assignee_id
            = dropdown_tag(user_dropdown_label(issuable.assignee_id, "Assignee"), options: { toggle_class: "js-dropdown-keep-input js-user-search js-issuable-form-dropdown js-assignee-search", title: "Select assignee", filter: true, dropdown_class: "dropdown-menu-user dropdown-menu-selectable dropdown-menu-assignee js-filter-submit",
              placeholder: "Search assignee", data: { first_user: current_user.try(:username), null_user: true, current_user: true, project_id: project.try(:id), selected: issuable.assignee_id, field_name: "#{issuable.class.model_name.param_key}[assignee_id]", default_label: "Assignee"} })
      .form-group.issue-milestone
        = f.label :milestone_id, "Milestone", class: "control-label #{"col-lg-4" if has_due_date}"
        .col-sm-10{ class: ("col-lg-8" if has_due_date) }
          .issuable-form-select-holder
            = render "shared/issuable/milestone_dropdown", selected: issuable.milestone, name: "#{issuable.class.model_name.param_key}[milestone_id]", show_any: false, show_upcoming: false, extra_class: "js-issuable-form-dropdown js-dropdown-keep-input", dropdown_title: "Select milestone"
      .form-group
        - has_labels = @labels && @labels.any?
        = f.label :label_ids, "Labels", class: "control-label #{"col-lg-4" if has_due_date}"
        = f.hidden_field :label_ids, multiple: true, value: ''
        .col-sm-10{ class: "#{"col-lg-8" if has_due_date} #{'issuable-form-padding-top' if !has_labels}" }
          .issuable-form-select-holder
            = render "shared/issuable/label_dropdown", classes: ["js-issuable-form-dropdown"], selected: issuable.labels, data_options: { field_name: "#{issuable.class.model_name.param_key}[label_ids][]", show_any: false, show_menu_above: 'true' }, dropdown_title: "Select label"

      - if issuable.respond_to?(:weight)
        .form-group
          = f.label :label_ids, class: "control-label #{"col-lg-4" if has_due_date}" do
            Weight
          .col-sm-10{ class: ("col-lg-8" if has_due_date) }
            = f.select :weight, issues_weight_options(issuable.weight, edit: true), { include_blank: true },
              { class: 'select2 js-select2', data: { placeholder: "Select weight" }}

    - if has_due_date
      .col-lg-6
        .form-group
          = f.label :due_date, "Due date", class: "control-label"
          .col-sm-10
            .issuable-form-select-holder
              = f.text_field :due_date, id: "issuable-due-date", class: "datepicker form-control", placeholder: "Select due date"
```

could be simplified by using partials:

```haml
= render 'metadata_form', issuable: issuable
```

and then the `_metadata_form.html.haml` could be as follows:

```haml
- return unless can?(current_user, :"admin_#{issuable.to_ability_name}", issuable.project)

- has_due_date = issuable.has_attribute?(:due_date)
%hr
.row
  %div{ class: (has_due_date ? "col-lg-6" : "col-sm-12") }
    .form-group.issue-assignee
      = f.label :assignee_id, "Assignee", class: "control-label #{"col-lg-4" if has_due_date}"
      .col-sm-10{ class: ("col-lg-8" if has_due_date) }
        .issuable-form-select-holder
          - if issuable.assignee_id
            = f.hidden_field :assignee_id
          = dropdown_tag(user_dropdown_label(issuable.assignee_id, "Assignee"), options: { toggle_class: "js-dropdown-keep-input js-user-search js-issuable-form-dropdown js-assignee-search", title: "Select assignee", filter: true, dropdown_class: "dropdown-menu-user dropdown-menu-selectable dropdown-menu-assignee js-filter-submit",
            placeholder: "Search assignee", data: { first_user: current_user.try(:username), null_user: true, current_user: true, project_id: project.try(:id), selected: issuable.assignee_id, field_name: "#{issuable.class.model_name.param_key}[assignee_id]", default_label: "Assignee"} })
    .form-group.issue-milestone
      = f.label :milestone_id, "Milestone", class: "control-label #{"col-lg-4" if has_due_date}"
      .col-sm-10{ class: ("col-lg-8" if has_due_date) }
        .issuable-form-select-holder
          = render "shared/issuable/milestone_dropdown", selected: issuable.milestone, name: "#{issuable.class.model_name.param_key}[milestone_id]", show_any: false, show_upcoming: false, extra_class: "js-issuable-form-dropdown js-dropdown-keep-input", dropdown_title: "Select milestone"
    .form-group
      - has_labels = @labels && @labels.any?
      = f.label :label_ids, "Labels", class: "control-label #{"col-lg-4" if has_due_date}"
      = f.hidden_field :label_ids, multiple: true, value: ''
      .col-sm-10{ class: "#{"col-lg-8" if has_due_date} #{'issuable-form-padding-top' if !has_labels}" }
        .issuable-form-select-holder
          = render "shared/issuable/label_dropdown", classes: ["js-issuable-form-dropdown"], selected: issuable.labels, data_options: { field_name: "#{issuable.class.model_name.param_key}[label_ids][]", show_any: false, show_menu_above: 'true' }, dropdown_title: "Select label"

    = render 'weight_form', issuable: issuable, has_due_date: has_due_date

  - if has_due_date
    .col-lg-6
      .form-group
        = f.label :due_date, "Due date", class: "control-label"
        .col-sm-10
          .issuable-form-select-holder
            = f.text_field :due_date, id: "issuable-due-date", class: "datepicker form-control", placeholder: "Select due date"
```

and then the `_weight_form.html.haml` could be as follows:

```haml
- return unless issuable.respond_to?(:weight)

- has_due_date = issuable.has_attribute?(:due_date)

.form-group
  = f.label :label_ids, class: "control-label #{"col-lg-4" if has_due_date}" do
    Weight
  .col-sm-10{ class: ("col-lg-8" if has_due_date) }
    = f.select :weight, issues_weight_options(issuable.weight, edit: true), { include_blank: true },
      { class: 'select2 js-select2', data: { placeholder: "Select weight" }}
```

Note:

- The safeguards at the top allows to get rid of an unneccessary indentation
level
- Here we only moved the 'Weight' code to a partial since this is the only
  EE-specific code in that view, so it's the most likely to conflict, but you
  are encouraged to use partials even for code that's in CE to logically split
  big views into several smaller files.

---

[Return to Development documentation](README.md)
