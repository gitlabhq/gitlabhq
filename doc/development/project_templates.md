---
stage: Manage
group: Organization
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Contribute to built-in project templates

## Adding a new built-in project template

This page provides instructions about how to contribute a
[built-in project template](../user/project/working_with_projects.md#create-a-project-from-a-built-in-template).

To contribute a built-in project template, you must complete the following tasks:

1. [Create a project template for GitLab review](#create-a-project-template-for-review)
1. [Add the template SVG icon to GitLab SVGs](#add-the-template-svg-icon-to-gitlab-svgs)
1. [Create a merge request with vendor details](#create-a-merge-request-with-vendor-details)

You can contribute the following types of project templates:

- Enterprise: For users with GitLab Premium and above.
- Non-enterprise: For users with GitLab Free and above.

### Prerequisites

To add or update an existing template, you must have the following tools
installed:

- `wget`
- `tar`

### Create a project template for review

1. In your selected namespace, create a public project.
1. Add the project content you want to use in the template. Do not include unnecessary assets or dependencies. For an example,
[see this project](https://gitlab.com/gitlab-org/project-templates/dotnetcore).
1. When the project is ready for review, [create an issue](https://gitlab.com/gitlab-org/gitlab/issues) with a link to your project.
   In your issue, mention the Create:Source Code [Backend Engineering Manager and Product Manager](https://about.gitlab.com/handbook/product/categories/#source-code-group)
   for the Templates feature.

### Add the template SVG icon to GitLab SVGs

If the project template has an SVG icon, you must add it to the
[GitLab SVGs project](https://gitlab.com/gitlab-org/gitlab-svgs/-/blob/main/README.md#adding-icons-or-illustrations)
before you can create a merge request with vendor details.

### Create a merge request with vendor details

Before GitLab can implement the project template, you must [create a merge request](../user/project/merge_requests/creating_merge_requests.md) in [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) that includes vendor details about the project.

1. [Export the project](../user/project/settings/import_export.md#export-a-project-and-its-data)
   and save the file as `<name>.tar.gz`, where `<name>` is the short name of the project.
   Move this file to the root directory of `gitlab-org/gitlab`.
1. In `gitlab-org/gitlab`, create and check out a new branch.
1. Edit the following files to include the project template:
   - For **non-Enterprise** project templates:
     - In `lib/gitlab/project_template.rb`, add details about the template
        in the `localized_templates_table` method. In the following example,
        the short name of the project is `hugo`:

        ```ruby
        ProjectTemplate.new('hugo', 'Pages/Hugo', _('Everything you need to create a GitLab Pages site using Hugo'), 'https://gitlab.com/pages/hugo', 'illustrations/logos/hugo.svg'),
        ```

        If the project doesn't have an SVG icon, exclude `, 'illustrations/logos/hugo.svg'`.

     - In `spec/support/helpers/project_template_test_helper.rb`, append the short name
       of the template in the `all_templates` method.
     - In `app/assets/javascripts/projects/default_project_templates.js`,
        add details of the template. For example:

        ```javascript
        hugo: {
          text: s__('ProjectTemplates|Pages/Hugo'),
          icon: '.template-option .icon-hugo',
        },
        ```

        If the project doesn't have an SVG icon, use `.icon-gitlab_logo`
        instead.
   - For **Enterprise** project templates:
     - In `ee/lib/ee/gitlab/project_template.rb`, in the `localized_ee_templates_table` method, add details about the template. For example:

        ```ruby
        ::Gitlab::ProjectTemplate.new('hipaa_audit_protocol', 'HIPAA Audit Protocol', _('A project containing issues for each audit inquiry in the HIPAA Audit Protocol published by the U.S. Department of Health & Human Services'), 'https://gitlab.com/gitlab-org/project-templates/hipaa-audit-protocol', 'illustrations/logos/asklepian.svg')
        ```

     - In `ee/spec/lib/gitlab/project_template_spec.rb`, add the short name
        of the template in the `.all` test.
     - In `ee/app/assets/javascripts/projects/default_project_templates.js`,
        add the template details. For example:

        ```javascript
        hipaa_audit_protocol: {
          text: s__('ProjectTemplates|HIPAA Audit Protocol'),
          icon: '.template-option .icon-hipaa_audit_protocol',
        },
        ```

1. Run the following Rake task, where `<path>/<name>` is the
   name you gave the template in `lib/gitlab/project_template.rb`:

   ```shell
   bin/rake gitlab:update_project_templates\[<path>/<name>\]
   ```

1. Regenerate `gitlab.pot`:

   ```shell
   bin/rake gettext:regenerate
   ```

1. After you run the scripts, there is one new file in `vendor/project_templates/` and four changed files. Commit all changes and push your branch to update the merge request. For an example, see this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25318).

### Test your built-in project with the GitLab Development Kit

Complete the following steps to test the project template in your own GitLab Development Kit instance:

1. Run the following Rake task, where `<path>/<name>` is the
   name you gave the template in `lib/gitlab/project_template.rb`:

   ```shell
   bin/rake gitlab:update_project_templates\[<path>/<name>\]
   ```

## Contribute an improvement to an existing template

To update an existing built-in project template, changes are usually made to the existing template, found in the [project-templates](https://gitlab.com/gitlab-org/project-templates) group. A merge request is made directly against the template and the Create:Source Code [Backend Engineering Manager and Product Manager](https://about.gitlab.com/handbook/product/categories/#source-code-group) pinged for review.

Sometimes it is necessary to completely replace the template files. In this case the process would be:

1. Create a merge request in the relevant project of the `project-templates` and `pages` group and mention `@gitlab-org/manage/import/backend` when you are ready for a review.
1. If your merge request is accepted, either:
   - [Create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues) to ask for the template to get updated.
   - [Create a merge request with vendor details](#create-a-merge-request-with-vendor-details) to update the template.

## For GitLab team members

Please ensure the merge request has been reviewed by the Security Counterpart before merging.

To review a merge request which changes a vendored project template, run the `check-template-changes` script:

```shell
scripts/check-template-changes vendor/project_templates/<template_name>.tar.gz
```

This script outputs a diff of the file changes against the default branch and also verifies that
the template repository matches the source template project.
