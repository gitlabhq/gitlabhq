---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# How to enable or disable GitLab CI/CD **(FREE)**

To effectively use GitLab CI/CD, you need:

- A valid [`.gitlab-ci.yml`](yaml/index.md) file present at the root directory
  of your project.
- A [runner](runners/index.md) properly set up.

You can read our [quick start guide](quick_start/index.md) to get you started.

If you are using an external CI/CD server like Jenkins or Drone CI, it is advised
to disable GitLab CI/CD in order to not have any conflicts with the commits status
API.

GitLab CI/CD is exposed via the `/pipelines` and `/jobs` pages of a project.
Disabling GitLab CI/CD in a project does not delete any previous jobs.
In fact, the `/pipelines` and `/jobs` pages can still be accessed, although
it's hidden from the left sidebar menu.

GitLab CI/CD is enabled by default on new installations and can be disabled
either:

- Individually under each project's settings.
- Site-wide by modifying the settings in `gitlab.yml` and `gitlab.rb` for source
  and Omnibus installations respectively.

This only applies to pipelines run as part of GitLab CI/CD. This doesn't enable or disable
pipelines that are run from an [external integration](../user/project/integrations/overview.md#integrations-listing).

## Per-project user setting

To enable or disable GitLab CI/CD Pipelines in your project:

1. Navigate to **Settings > General > Visibility, project features, permissions**.
1. Expand the **Repository** section
1. Enable or disable the **Pipelines** toggle as required.

**Project visibility** also affects pipeline visibility. If set to:

- **Private**: Only project members can access pipelines.
- **Internal** or **Public**: Pipelines can be set to either **Only Project Members**
  or **Everyone With Access** via the dropdown box.

Press **Save changes** for the settings to take effect.

## Site-wide admin setting

You can disable GitLab CI/CD site-wide, by modifying the settings in `gitlab.yml`
for source installations, and `gitlab.rb` for Omnibus installations.

Two things to note:

- Disabling GitLab CI/CD affects only newly-created projects. Projects that
  had it enabled prior to this modification work as before.
- Even if you disable GitLab CI/CD, users can still enable it in the
  project's settings.

For installations from source, open `gitlab.yml` with your editor and set
`builds` to `false`:

```yaml
## Default project features settings
default_projects_features:
  issues: true
  merge_requests: true
  wiki: true
  snippets: false
  builds: false
```

Save the file and restart GitLab:

```shell
sudo service gitlab restart
```

For Omnibus installations, edit `/etc/gitlab/gitlab.rb` and add the line:

```ruby
gitlab_rails['gitlab_default_projects_features_builds'] = false
```

Save the file and reconfigure GitLab:

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
