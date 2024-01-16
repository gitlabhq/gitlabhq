---
stage: Govern
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Custom Roles

Ultimate customers can create custom roles and define those roles by assigning specific abilities.

For example, a user could create an "Engineer" role with `read code` and `admin merge requests` abilities, but without abilities like `admin issues`.

In this context, the terms "permission" and "ability" are often used interchangeably.

- "Ability" is an action a user can do. These map to [Declarative Policy abilities](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/doc/defining-policies.md#rules) and live in Policy classes in `ee/app/policies/*`.
- "Permission" is how we refer to an ability [in user-facing documentation](../../user/permissions.md). The documentation of permissions is manually generated so there is not necessarily a 1:1 mapping of the permissions listed in documentation and the abilities defined in Policy classes.

## Custom roles vs static roles

In GitLab 15.9 and earlier, GitLab only had [static roles](predefined_roles.md) as a permission system. In this system, there are a few predefined roles that are statically assigned to certain abilities. These static roles are not customizable by customers.

With custom roles, the customers can decide which abilities they want to assign to certain user groups. For example:

- In the static role system, reading of vulnerabilities is limited to a Developer role.
- In the custom role system, a customer can assign this ability to a new custom role based on any static role.

Like static roles, custom roles are [inherited](../../user/project/members/index.md#inherited-membership) within a group hierarchy. If a user has custom role for a group, that user will also have a custom role for any projects or subgroups within the group.

## Technical overview

- Individual custom roles are stored in the `member_roles` table (`MemberRole` model).
- A `member_roles` record is associated with top-level groups (not subgroups) via the `namespace_id` foreign key.
- A Group or project membership (`members` record) is associated with a custom role via the `member_role_id` foreign key.
- A Group or project membership can be associated with any custom role that is defined on the root-level group of the group or project.
- The `member_roles` table includes individual permissions and a `base_access_level` value.
- The `base_access_level` must be a [valid access level](../../api/access_requests.md#valid-access-levels).
  The `base_access_level` determines which abilities are included in the custom role. For example, if the `base_access_level` is `10`, the custom role will include any abilities that a static Guest role would receive, plus any additional abilities that are enabled by the `member_roles` record by setting an attribute, such as `read_code`, to true.
- A custom role can enable additional abilities for a `base_access_level` but it cannot disable a permission. As a result, custom roles are "additive only". The rationale for this choice is [in this comment](https://gitlab.com/gitlab-org/gitlab/-/issues/352891#note_1059561579).
- Custom role abilities are supported at project level and group level.

## How to implement a new ability for custom roles

Usually 2-3 merge requests should be created for a new ability. The rough guidance is following:

1. Pick a feature you want to add abilities to custom roles.
1. Refactor & consolidate abilities for the feature (1-2 merge requests depending on the feature complexity)
1. Implement a new ability (1 merge request)

### Refactoring abilities

#### Finding existing abilities checks

Abilities are often [checked in multiple locations](../permissions/authorizations.md#where-should-permissions-be-checked) for a single endpoint or web request. Therefore, it can be difficult to find the list of authorization checks that are run for a given endpoint.

To assist with this, you can locally set `GITLAB_DEBUG_POLICIES=true`.

This outputs information about which abilities are checked in the requests
made in any specs that you run. The output also includes the line of code where the
authorization check was made. Caller information is especially helpful in cases
where there is metaprogramming used because those cases are difficult to find by
grepping for ability name strings.

For example:

```shell
# example spec run

GITLAB_DEBUG_POLICIES=true bundle exec rspec spec/controllers/groups_controller_spec.rb:162

# permissions debug output when spec is run; if multiple policy checks are run they will all be in the debug output.

POLICY CHECK DEBUG -> policy: GlobalPolicy, ability: create_group, called_from: ["/gitlab/app/controllers/application_controller.rb:245:in `can?'", "/gitlab/app/controllers/groups_controller.rb:255:in `authorize_create_group!'"]
```

Use this setting to learn more about authorization checks while
refactoring. You should not keep this setting enabled for any specs on the default branch.

#### Understanding logic for individual abilities

References to an ability may appear in a `DeclarativePolicy` class many times
and depend on conditions and rules which reference other abilities. As a result,
it can be challenging to know exactly which conditions apply to a particular
ability.

`DeclarativePolicy` provides a `ability_map` for each policy class, which
pulls all rules for an ability into an array.

For example:

```ruby
> GroupPolicy.ability_map.map.select { |k,v| k == :read_group_member }
=> {:read_group_member=>[[:enable, #<Rule can?(:read_group)>], [:prevent, #<Rule ~can_read_group_member>]]}

> GroupPolicy.ability_map.map.select { |k,v| k == :read_group }
=> {:read_group=>
  [[:enable, #<Rule public_group>],
   [:enable, #<Rule logged_in_viewable>],
   [:enable, #<Rule guest>],
   [:enable, #<Rule admin>],
   [:enable, #<Rule has_projects>],
   [:enable, #<Rule read_package_registry_deploy_token>],
   [:enable, #<Rule write_package_registry_deploy_token>],
   [:prevent, #<Rule all?(~public_group, ~admin, user_banned_from_group)>],
   [:enable, #<Rule auditor>],
   [:prevent, #<Rule needs_new_sso_session>],
   [:prevent, #<Rule all?(ip_enforcement_prevents_access, ~owner, ~auditor)>]]}
```

`DeclarativePolicy` also provides a `debug` method that can be used to
understand the logic tree for a specific object and actor. The output is similar
to the list of rules from `ability_map`. But, `DeclarativePolicy` stops
evaluating rules after you `prevent` an ability, so it is possible that
not all conditions are called.

Example:

```ruby
policy = GroupPolicy.new(User.last,  Group.last)
policy.debug(:read_group)

- [0] enable when public_group ((@custom_guest_user1 : Group/139))
- [0] enable when logged_in_viewable ((@custom_guest_user1 : Group/139))
- [0] enable when admin ((@custom_guest_user1 : Group/139))
- [0] enable when auditor ((@custom_guest_user1 : Group/139))
- [14] prevent when all?(~public_group, ~admin, user_banned_from_group) ((@custom_guest_user1 : Group/139))
- [14] prevent when needs_new_sso_session ((@custom_guest_user1 : Group/139))
- [16] enable when guest ((@custom_guest_user1 : Group/139))
- [16] enable when has_projects ((@custom_guest_user1 : Group/139))
- [16] enable when read_package_registry_deploy_token ((@custom_guest_user1 : Group/139))
- [16] enable when write_package_registry_deploy_token ((@custom_guest_user1 : Group/139))
  [21] prevent when all?(ip_enforcement_prevents_access, ~owner, ~auditor) ((@custom_guest_user1 : Group/139))

=> #<DeclarativePolicy::Runner::State:0x000000015c665050
 @called_conditions=
  #<Set: {
   "/dp/condition/GroupPolicy/public_group/Group:139",
   "/dp/condition/GroupPolicy/logged_in_viewable/User:83,Group:139",
   "/dp/condition/BasePolicy/admin/User:83",
   "/dp/condition/BasePolicy/auditor/User:83",
   "/dp/condition/GroupPolicy/user_banned_from_group/User:83,Group:139",
   "/dp/condition/GroupPolicy/needs_new_sso_session/User:83,Group:139",
   "/dp/condition/GroupPolicy/guest/User:83,Group:139",
   "/dp/condition/GroupPolicy/has_projects/User:83,Group:139",
   "/dp/condition/GroupPolicy/read_package_registry_deploy_token/User:83,Group:139",
   "/dp/condition/GroupPolicy/write_package_registry_deploy_token/User:83,Group:139"}>,
 @enabled=false,
 @prevented=true>
```

#### Abilities consolidation

Every feature added to custom roles should have minimal abilities. For most features, having `read_*` and `admin_*` should be enough. You should consolidate all:

- View-related abilities under `read_*`. For example, viewing a list or detail.
- Object updates under `admin_*`. For example, updating an object, adding assignees or closing it that object. Usually, a role that enables `admin_` has to have also `read_` abilities enabled. This is defined in `requirement` option in the `ALL_CUSTOMIZABLE_PERMISSIONS` hash on `MemberRole` model.

There might be features that require additional abilities but try to minimize those. You can always ask members of the Authentication and Authorization group for their opinion or help.

This is also where your work should begin. Take all the abilities for the feature you work on, and consolidate those abilities into `read_`, `admin_`, or additional abilities if necessary.

Many abilities in the `GroupPolicy` and `ProjectPolicy` classes have many
redundant policies. There is an [epic for consolidating these Policy classes](https://gitlab.com/groups/gitlab-org/-/epics/6689).
If you encounter similar permissions in these classes, consider refactoring so
that they have the same name.

For example, you see in `GroupPolicy` that there is an ability called
`read_group_security_dashboard` and in `ProjectPolicy` has an ability called
`read_project_security_dashboard`. You'd like to make both customizable. Rather
than adding a row to the `member_roles` table for each ability, consider
renaming them to `read_security_dashboard` and adding `read_security_dashboard`
to the `member_roles` table. This is more expected because it means that
enabling `read_security_dashboard` on the parent group will enable the custom role.
For example, `GroupPolicy` has an ability called `read_group_security_dashboard` and `ProjectPolicy` has an ability
called `read_project_security_dashboard`. If you would like to make both customizable, rather than adding a row to the
`member_roles` table for each ability, consider renaming them to `read_security_dashboard` and adding
`read_security_dashboard` to the `member_roles` table. This convention means that enabling `read_security_dashboard` on
the parent group will allow the custom role to access the group security dashboard and the project security dashboard
for each project in that group. Enabling the same permission on a specific project will allow access to that projects'
security dashboard.

### Implement a new ability

To add a new ability to a custom role:

- Generate YAML file by running `./ee/bin/custom-ability` generator
- Add a new column to `member_roles` table, either manually or by running `custom_roles:code`  generator, eg. by running `rails generate gitlab:custom_roles:code --ability new_ability_name`. The ability parameter is case sensitive and has to exactly match the permission name from the YAML file.
- Add the ability to the respective Policy for example in [this change in merge request 114734](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114734/diffs#diff-content-edcbe28bdecbd848d4d9efdc5b5e9bddd2a7299e).
- Update the specs. Don't forget to add a spec to `ee/spec/requests/custom_roles` - the spec template file was pre-generated if you used the code generator
- Compile the documentation by running `bundle exec rake gitlab:custom_roles:compile_docs`
- Update the GraphQL documentation by running `bundle exec rake gitlab:graphql:compile_docs`

Examples of merge requests adding new abilities to custom roles:

- [Read code](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256)
- [Read vulnerability](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114734)
- [Admin vulnerability](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121534)

The above merge requests don't use YAML files and code generators. Some of the changes are not needed anymore. We will update the documentation once we have a permission implemented using the generators.

If you have any concerns, put the new ability behind a feature flag.

#### Documenting handling the feature flag

- When you introduce a new custom ability under a feature flag, add the `feature_flag` attribute to the appropriate ability YAML file.
- When you enable the ability by default, add the `feature_flag_enabled_milestone` and `feature_flag_enabled_mr` attributes to the appropriate ability YAML file and regenerate the documentation.
- You do not have to include these attributes in the YAML file if the feature flag is enabled by default in the same release as the ability is introduced.

#### Testing

Unit tests are preferred to test out changes to any policies affected by the
addition of new custom permissions. Custom Roles is an Ultimate tier feature so
these tests can be found in the `ee/spec/policies` directory. The [spec file](https://gitlab.com/gitlab-org/gitlab/-/blob/13baa4e8c92a56260591a5bf0a58d3339890ee10/ee/spec/policies/project_policy_spec.rb#L2726-2740) for
the `ProjectPolicy` contains shared examples that can be used to test out the
following conditions:

- when the `custom_roles` licensed feature is not enabled
- when the `custom_roles` licensed feature is enabled
  - when a user is a member of a custom role via an inherited group member
  - when a user is a member of a custom role via a direct group member
  - when a user is a member of a custom role via a direct project membership

Below is an example for testing out `ProjectPolicy` related changes.

```ruby
  context 'for a role with `custom_permission` enabled' do
    let(:member_role_abilities) { { custom_permission: true } }
    let(:allowed_abilities) { [:custom_permission] }

    it_behaves_like 'custom roles abilities'
  end
```

Request specs are preferred to test out any endpoint that allow access via a custom role permission.
This includes controllers, REST API, and GraphQL. Examples of request specs can be found in `ee/spec/requests/custom_roles/`. In this directory you will find a sub-directory named after each permission that can be enabled via a custom role.
The `custom_roles` licensed feature must be enabled to test this functionality.

Below is an example of the typical setup that is required to test out a
Rails Controller endpoint.

```ruby
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :in_group) }
  let_it_be(:role) { create(:member_role, :guest, namespace: project.group, custom_permission: true) }
  let_it_be(:membership) { create(:project_member, :guest, member_role: role, user: user, project: project) }

  before do
    stub_licensed_features(custom_roles: true)
    sign_in(user)
  end

  describe MyController do
    describe '#show' do
      it 'allows access' do
        get my_controller_path(project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end
  end
```

Below is an example of the typical setup that is required to test out a GraphQL
mutation.

```ruby
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :in_group) }
  let_it_be(:role) { create(:member_role, :guest, namespace: project.group, custom_permission: true) }
  let_it_be(:membership) { create(:project_member, :guest, member_role: role, user: user, project: project) }

  before do
    stub_licensed_features(custom_roles: true)
  end

  describe MyMutation do
    include GraphqlHelpers

    describe '#show' do
      it 'allows access' do
        post_graphql_mutation(graphql_mutation(:my_mutation, {
          example: "Example"
        }), current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        mutation_response = graphql_mutation_response(:my_mutation)
        expect(mutation_response).to be_present
        expect(mutation_response["errors"]).to be_empty
      end
    end
  end
```

[`GITLAB_DEBUG_POLICIES=true`](#finding-existing-abilities-checks) can be used
to troubleshoot runtime policy decisions.

## Custom abilities definition

All new custom abilities must have a type definition stored in `ee/config/custom_abilities` that contains a single source of truth for every ability that is part of custom roles feature.

### Add a new custom ability definition

To add a new custom ability:

1. Create the YAML definition. You can either:
   - Use the `ee/bin/custom-ability` CLI to create the YAML definition automatically.
   - Perform manual steps to create a new file in `ee/config/custom_abilities/` with the filename matching the name of the ability name.
1. Add contents to the file that conform to the [schema](#schema) defined in `ee/config/custom_abilities/types/type_schema.json`.
1. Add [tests](#testing) for the new ability in `ee/spec/requests/custom_roles/` with a new directory named after the ability name.

### Schema

| Field | Required | Description |
| ----- | -------- |--------------|
| `name` | yes     | Unique, lowercase and underscored name describing the custom ability. Must match the filename. |
| `description` | yes | Human-readable description of the custom ability. |
| `feature_category` | yes | Name of the feature category. For example, `vulnerability_management`. |
| `introduced_by_issue` | yes | Issue URL that proposed the addition of this custom ability. |
| `introduced_by_mr` | no | MR URL that added this custom ability. |
| `milestone` | yes | Milestone in which this custom ability was added. |
| `group_ability` | yes | Indicate whether this ability is checked on group level. |
| `project_ability` | yes | Indicate whether this ability is checked on project level. |
| `skip_seat_consumption` | yes | Indicate wheter this ability should be skiped when counting licensed users. |

### Privilege escalation consideration

A base role typically has permissions that allow creation or management of artifacts corresponding to the base role when interacting with that artifact. For example, when a `Developer` creates an access token for a project, it is created with `Developer` access encoded into that credential. It is important to keep in mind that as new custom permissions are created, there might be a risk of elevated privileges when interacting with GitLab artifacts, and appropriate safeguards or base role checks should be added.

### Consuming seats

If a new user with a role `Guest` is added to a member role that includes enablement of an ability that is **not** in the `CUSTOMIZABLE_PERMISSIONS_EXEMPT_FROM_CONSUMING_SEAT` array, a seat is consumed. We simply want to make sure we are charging Ultimate customers for guest users, who have "elevated" abilities. This only applies to billable users on SaaS (billable users that are counted towards namespace subscription). More details about this topic can be found in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390269).
