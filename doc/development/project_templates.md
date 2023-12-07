---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Contribute to built-in project templates

## Adding a new built-in project template

If you'd like to contribute a new built-in project template to be distributed with GitLab, please do the following:

1. Create a new public project with the project content you'd like to contribute in a namespace of your choosing. You can view a working example [here](https://gitlab.com/gitlab-org/project-templates/dotnetcore).
   - Projects should be as simple as possible and free of any unnecessary assets or dependencies.
1. When the project is ready for review, please create a new issue in [GitLab](https://gitlab.com/gitlab-org/gitlab/issues) with a link to your project.
   - In your issue, `@` mention the relevant Backend Engineering Manager and Product Manager for the [Create:Source Code group](https://about.gitlab.com/handbook/product/categories/#source-code-group).

To make the project template available when creating a new project, the vendoring process will have to be completed:

1. Create a working template ([example](https://gitlab.com/gitlab-org/project-templates/dotnetcore))
   - 2 types of built-in templates are available within GitLab:
     - **Standard templates**: Available in GitLab Core, Starter and above (this is the most common type of built-in template).
       - To contribute a standard template:
         - Add details of the template in the `localized_templates_table` method in `gitlab/lib/gitlab/project_template.rb`,
         - Add details of the template in `spec/lib/gitlab/project_template_spec.rb`, in the test for the `all` method, and
         - Add details of the template in `gitlab/app/assets/javascripts/projects/default_project_templates.js`.
         - See MR [!25318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25318) for an example
     - **Enterprise templates**: Introduced in GitLab 12.10, that are available only in GitLab Gold & Ultimate.
       - To contribute an Enterprise template:
         - Add details of the template in the `localized_ee_templates_table` method in `gitlab/ee/lib/ee/gitlab/project_template.rb`,
         - Add details of the template in `gitlab/ee/spec/lib/gitlab/project_template_spec.rb`, in the `enterprise_templates` method, and
         - Add details of the template in `gitlab/ee/app/assets/javascripts/projects/default_project_templates.js`.
         - See MR [!28187](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28187) for an example.

1. Run the following in the `gitlab` project, where `$name` is the name you gave the template in `gitlab/project_template.rb`:

   ```shell
   bin/rake gitlab:update_project_templates[$name]
   ```

1. Run the `bundle_repo` script. Make sure to pass the correct arguments, or the script may damage the folder structure.
1. Add exported project (`$name.tar.gz`) to `gitlab/vendor/project_templates` and remove the resulting build folders `tar-base` and `project`.
1. Run `tooling/bin/gettext_extractor locale/gitlab.pot` in the `gitlab` project and commit new `.pot` file.
1. Add a changelog entry in the commit message (for example, `Changelog: added`).
   For more information, see [Changelog entries](changelog.md).
1. Add an icon to [`gitlab-svgs`](https://gitlab.com/gitlab-org/gitlab-svgs), as shown in
   [this example](https://gitlab.com/gitlab-org/gitlab-svgs/merge_requests/195). If a logo
   is not available for the project, use the default 'Tanuki' logo instead.
1. Run `yarn run svgs` on `gitlab-svgs` project and commit result.
1. Forward changes in `gitlab-svgs` project to the `main` branch. This involves:
   - Merging your MR in `gitlab-svgs`
   - [The bot](https://gitlab.com/gitlab-org/frontend/renovate-gitlab-bot/)
     will pick the new release up and create an MR in `gitlab-org/gitlab`.
1. After the bot-created MR created above is merged, you can rebase your template MR onto the updated `master` to pick up the new SVGs.
1. Test everything is working.

### Contributing an improvement to an existing template

Existing templates are available in the [project-templates](https://gitlab.com/gitlab-org/project-templates)
group.

To contribute a change, please open a merge request in the relevant project
and mention `@gitlab-org/manage/import/backend` when you are ready for a review.

Then, if your merge request gets accepted, either open an issue on
`gitlab` to ask for it to get updated, or open a merge request updating
the vendored template using [these instructions](rake_tasks.md#update-project-templates).

### Test your built-in project with the GitLab Development Kit

Complete the following steps to test the project template in your own GitLab Development Kit instance:

1. Run the following Rake task, where `<path>/<name>` is the
   name you gave the template in `lib/gitlab/project_template.rb`:

   ```shell
   bin/rake gitlab:update_project_templates\[<path>/<name>\]
   ```

## For GitLab team members

Please ensure the merge request has been reviewed by the Security Counterpart before merging.

To review a merge request which changes a vendored project template, run the `check-template-changes` script:

```shell
scripts/check-template-changes vendor/project_templates/<template_name>.tar.gz
```

This script outputs a diff of the file changes against the default branch and also verifies that
the template repository matches the source template project.
