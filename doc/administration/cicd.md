---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# GitLab CI/CD instance configuration **(FREE SELF)**

GitLab CI/CD is enabled by default in all new projects on an instance. You can configure
the instance to have [GitLab CI/CD disabled by default](#disable-gitlab-cicd-in-new-projects)
in new projects.

You can still choose to [enable GitLab CI/CD in individual projects](../ci/enable_or_disable_ci.md#enable-cicd-in-a-project)
at any time.

## Disable GitLab CI/CD in new projects

You can set GitLab CI/CD to be disabled by default in all new projects by modifying the settings in:

- `gitlab.yml` for source installations.
- `gitlab.rb` for Omnibus GitLab installations.

Existing projects that already had CI/CD enabled are unchanged. Also, this setting only changes
the project default, so project owners can still enable CI/CD in the project settings.

For installations from source:

1. Open `gitlab.yml` with your editor and set `builds` to `false`:

   ```yaml
   ## Default project features settings
   default_projects_features:
     issues: true
     merge_requests: true
     wiki: true
     snippets: false
     builds: false
   ```

1. Save the `gitlab.yml` file.

1. Restart GitLab:

   ```shell
   sudo service gitlab restart
   ```

For Omnibus GitLab installations:

1. Edit `/etc/gitlab/gitlab.rb` and add this line:

   ```ruby
   gitlab_rails['gitlab_default_projects_features_builds'] = false
   ```

1. Save the `/etc/gitlab/gitlab.rb` file.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
