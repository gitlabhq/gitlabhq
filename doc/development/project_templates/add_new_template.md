---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Contribute to built-in project templates
---

GitLab provides some
[built-in project templates](../../user/project/_index.md#create-a-project-from-a-built-in-template)
that you can use when creating a new project.

Built-in templates are sourced from the following groups:

- [`gitlab-org/project-templates`](https://gitlab.com/gitlab-org/project-templates)
- [`pages`](https://gitlab.com/pages)

Prerequisites:

- You must have a working [GitLab Development Kit (GDK) environment](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md).
  In particular, PostgreSQL, Praefect, and `sshd` must be working.
- `wget` should be installed.

## Add a new built-in project template

If you'd like to contribute a new built-in project template to be distributed
with GitLab, there are a few steps to follow.

### Create the project

1. Create a new public project with the project content you'd like to contribute in a namespace of your choosing. You can view a [working example](https://gitlab.com/gitlab-org/project-templates/dotnetcore).
   - Projects should be free of any unnecessary assets or dependencies.
1. When the project is ready for review, [create a new issue](https://gitlab.com/gitlab-org/gitlab/issues/new) with a link to your project.
   - In your issue, `@` mention the relevant Backend Engineering Manager and Product Manager for the [Create:Source Code group](https://handbook.gitlab.com/handbook/product/categories/#source-code-group).

### Add the logo in `gitlab-svgs`

All templates fetch their icons from the
[`gitlab-svgs`](https://gitlab.com/gitlab-org/gitlab-svgs) library, so if the
icon of the template you add is not present, you have to submit one.

See how to add a [third-party logo](https://gitlab.com/gitlab-org/gitlab-svgs/-/tree/main#adding-third-party-logos-or-trademarks).

After the logo is added to the `main` branch,
[the bot](https://gitlab.com/gitlab-org/frontend/renovate-gitlab-bot/) picks the
new release up and create an MR in `gitlab-org/gitlab`. You can now proceed to
the next step.

### Add the template details

Two types of built-in templates are available in GitLab:

- **Standard templates**: Available in all GitLab tiers.
- **Enterprise templates**: Available only in GitLab Premium and Ultimate.

To make the project template available when creating a new project, you must
follow the vendoring process to create a working template.

#### Standard template

NOTE:
See merge request [25318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25318) for an example.

To contribute a standard template:

1. Add the details of the template in the `localized_templates_table` method in [`lib/gitlab/project_template.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/project_template.rb) using the following scheme:

   ```ruby
   ProjectTemplate.new('<template_name>', '<template_short_description>', _('<template_long_description>'), '<template_project_link>', 'illustrations/logos/<template_logo_name>.svg'),
   ```

1. Add the details of the template in [`app/assets/javascripts/projects/default_project_templates.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/projects/default_project_templates.js).
1. Add the template name to [`spec/support/helpers/project_template_test_helper.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/helpers/project_template_test_helper.rb).

#### Enterprise template

NOTE:
See merge request [28187](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28187) for an example.

To contribute an Enterprise template:

1. Add details of the template in the `localized_ee_templates_table` method in [`ee/lib/ee/gitlab/project_template.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/project_template.rb) using the following scheme:

   ```ruby
   ProjectTemplate.new('<template_name>', '<template_short_description>', _('<template_long_description>'), '<template_project_link>', 'illustrations/logos/<template_logo_name>.svg'),
   ```

1. Add the template name in the list of `let(:enterprise_templates)` in [`ee/spec/lib/gitlab/project_template_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/lib/gitlab/project_template_spec.rb).
1. Add details of the template in [`ee/app/assets/javascripts/projects/default_project_templates.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/projects/default_project_templates.js).

### Populate the template details

1. Start GDK:

   ```shell
   gdk start
   ```

1. Run the following in the `gitlab` project, where `<template_name>` is the name you
   gave the template in `gitlab/project_template.rb`:

   ```shell
   bin/rake "gitlab:update_project_templates[<template_name>]"
   ```

1. Regenerate the localization file in the `gitlab` project and commit the new `.pot` file:

   ```shell
   bin/rake gettext:regenerate
   ```

1. Add a changelog entry in the commit message (for example, `Changelog: added`).
   For more information, see [Changelog entries](../changelog.md).

## Update an existing built-in project template

To contribute a change:

1. Open a merge request in the relevant project, and leave the following comment
   when you are ready for a review:

   ```plaintext
   @gitlab-org/manage/import/backend this is a contribution to update the project
   template and is ready for review!

   @gitlab-bot ready
   ```

1. If your merge request gets accepted:

   - Either [open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new)
     to ask for it to get updated.
   - Or update the vendored template and open a merge request:

     ```shell
     bin/rake "gitlab:update_project_templates[<template_name>]"
     ```

## Test your built-in project with the GitLab Development Kit

Complete the following steps to test the project template in your own
GDK instance:

1. Start GDK:

   ```shell
   gdk start
   ```

1. Run the following Rake task, where `<template_name>` is the
   name of the template in `lib/gitlab/project_template.rb`:

   ```shell
   bin/rake "gitlab:update_project_templates[<template_name>]"
   ```

1. Visit GitLab in your browser and create a new project by selecting the
   project template.

## For GitLab team members

Ensure all merge requests have been reviewed by the Security counterpart before merging.

### Update all templates

Starting a project from a template needs this project to be exported. On a
up to date default branch run:

```shell
gdk start # postgres, praefect, and sshd are required
bin/rake gitlab:update_project_templates
git checkout -b update-project-templates
git add vendor/project_templates
git commit
git push -u origin update-project-templates
```

Now create a merge request and assign to a Security counterpart to merge.

### Update a single template

To update just a single template instead of all of them, specify the template name
between square brackets. For example, for the `jekyll` template, run:

```shell
bin/rake "gitlab:update_project_templates[jekyll]"
```

### Review a template merge request

To review a merge request which changes one or more vendored project templates,
run the `check-template-changes` script:

```shell
scripts/check-template-changes vendor/project_templates/<template_name>.tar.gz
```

This script outputs a diff of the file changes against the default branch and also verifies that
the template repository matches the source template project.
