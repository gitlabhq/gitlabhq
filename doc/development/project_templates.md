---
stage: Manage
group: Workspace
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Contribute to GitLab project templates

Thanks for considering a contribution to the GitLab
[built-in project templates](../user/project/working_with_projects.md#create-a-project-from-a-built-in-template).

## Prerequisites

To add a new or update an existing template, you must have the following tools
installed:

- `wget`
- `tar`
- `jq`

## Create a new project

To contribute a new built-in project template to be distributed with GitLab:

1. Create a new public project with the project content you'd like to contribute
   in a namespace of your choosing. You can [view a working example](https://gitlab.com/gitlab-org/project-templates/dotnetcore).
   Projects should be as simple as possible and free of any unnecessary assets or dependencies.
1. When the project is ready for review, [create a new issue](https://gitlab.com/gitlab-org/gitlab/issues) with a link to your project.
   In your issue, `@` mention the relevant Backend Engineering Manager and Product
   Manager for the [Templates feature](https://about.gitlab.com/handbook/product/categories/#source-code-group).

## Add the SVG icon to GitLab SVGs

If the template you're adding has an SVG icon, you need to first add it to
<https://gitlab.com/gitlab-org/gitlab-svgs>:

1. Follow the steps outlined in the
   [GitLab SVGs project](https://gitlab.com/gitlab-org/gitlab-svgs/-/blob/main/README.md#adding-icons-or-illustrations)
   and submit a merge request.
1. When the merge request is merged, `gitlab-bot` will pull the new changes in
   the `gitlab-org/gitlab` project.
1. You can now continue on the vendoring process.

## Vendoring process

To make the project template available when creating a new project, the vendoring
process will have to be completed:

1. [Export the project](../user/project/settings/import_export.md#export-a-project-and-its-data)
   you created in the previous step and save the file as `<name>.tar.gz`, where
   `<name>` is the short name of the project.
1. Edit the following files to include the project template. Two types of built-in
   templates are available within GitLab:
   - **Normal templates**: Available in GitLab Free and above (this is the most common type of built-in template).
     See MR [!25318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25318) for an example.

     To add a normal template:

     1. Open `lib/gitlab/project_template.rb` and add details of the template
        in the `localized_templates_table` method. In the following example,
        the short name of the project is `hugo`:

        ```ruby
        ProjectTemplate.new('hugo', 'Pages/Hugo', _('Everything you need to create a GitLab Pages site using Hugo'), 'https://gitlab.com/pages/hugo', 'illustrations/logos/hugo.svg'),
        ```

        If the vendored project doesn't have an SVG icon, omit `, 'illustrations/logos/hugo.svg'`.

     1. Open `spec/lib/gitlab/project_template_spec.rb` and add the short name
        of the template in the `.all` test.
     1. Open `app/assets/javascripts/projects/default_project_templates.js` and
        add details of the template. For example:

        ```javascript
        hugo: {
          text: s__('ProjectTemplates|Pages/Hugo'),
          icon: '.template-option .icon-hugo',
        },
        ```

        If the vendored project doesn't have an SVG icon, use `.icon-gitlab_logo`
        instead.

   - **Enterprise templates**: Introduced in GitLab 12.10, that are available only in GitLab Premium and above.
     See MR [!28187](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28187) for an example.

     To add an Enterprise template:

     1. Open `ee/lib/ee/gitlab/project_template.rb` and add details of the template
        in the `localized_ee_templates_table` method. For example:

        ```ruby
        ::Gitlab::ProjectTemplate.new('hipaa_audit_protocol', 'HIPAA Audit Protocol', _('A project containing issues for each audit inquiry in the HIPAA Audit Protocol published by the U.S. Department of Health & Human Services'), 'https://gitlab.com/gitlab-org/project-templates/hipaa-audit-protocol', 'illustrations/logos/asklepian.svg')
        ```

     1. Open `ee/spec/lib/gitlab/project_template_spec.rb` and add the short name
        of the template in the `.all` test.
     1. Open `ee/app/assets/javascripts/projects/default_project_templates.js` and
        add details of the template. For example:

        ```javascript
        hipaa_audit_protocol: {
          text: s__('ProjectTemplates|HIPAA Audit Protocol'),
          icon: '.template-option .icon-hipaa_audit_protocol',
        },
        ```

1. Run the `vendor_template` script. Make sure to pass the correct arguments:

   ```shell
   scripts/vendor_template <git_repo_url> <name> <comment>
   ```

1. Regenerate `gitlab.pot`:

   ```shell
   bin/rake gettext:regenerate
   ```

1. By now, there should be one new file under `vendor/project_templates/` and
   4 changed files. Commit all of them in a new branch and create a merge
   request.

## Test with GDK

If you are using the GitLab Development Kit (GDK) you must disable `praefect`
and regenerate the Procfile, as the Rake task is not currently compatible with it:

```yaml
# gitlab-development-kit/gdk.yml
praefect:
  enabled: false
```

1. Follow the steps described in the [vendoring process](#vendoring-process).
1. Run the following Rake task where `<path>/<name>` is the
   name you gave the template in `lib/gitlab/project_template.rb`:

   ```shell
   bin/rake gitlab:update_project_templates[<path>/<name>]
   ```

You can now test to create a new project by importing the new template in GDK.

## Contribute an improvement to an existing template

Existing templates are imported from the following groups:

- [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
- [`pages`](htps://gitlab.com/pages)

To contribute a change, open a merge request in the relevant project
and mention `@gitlab-org/manage/import/backend` when you are ready for a review.

Then, if your merge request gets accepted, either [open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues)
to ask for it to get updated, or open a merge request updating
the [vendored template](#vendoring-process).
