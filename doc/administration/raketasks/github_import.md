---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitHub import Rake task (deprecated)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390690) in GitLab 15.9, Rake task no longer automatically creates namespaces or groups that don't exist.
> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/428225) in GitLab 16.6 and is planned for
removal in GitLab 17.0. Use the [GitHub import feature](../../user/project/import/github.md) instead.

To retrieve and import GitHub repositories, you need a [GitHub personal access token](https://github.com/settings/tokens).
A username should be passed as the second argument to the Rake task,
which becomes the owner of the project. You can resume an import
with the same command.

Bear in mind that the syntax is very specific. Remove any spaces in the argument block and
before/after the brackets. Also, some shells (for example, Zsh) can interpret the open/close brackets
(`[]`) separately. You may want to either escape the brackets or use double quotes.

You can only import repositories that are in the namespace of the owner of the GitHub personal access token being used to import. For more information, see
[issue 424105](https://gitlab.com/gitlab-org/gitlab/-/issues/424105).

Prerequisites:

- At least the Maintainer role on the destination group to import to.

## Rate limit

If the GitHub [rate limit](https://docs.github.com/en/rest/rate-limit) is reached while
importing, the importing process waits (`sleep()`) until it can continue importing.

## Importing multiple projects

To import a project from the list of your GitHub projects available:

```shell
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar]" RAILS_ENV=production
```

In this case, `access_token` is your GitHub personal access token, `root`
is your GitLab username, and `foo/bar` is the new GitLab namespace/project
created from your GitHub project. Subgroups are also possible: `foo/foo/bar`.

## Importing a single project

To import a specific GitHub project (named `foo/github_repo` here):

```shell
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar,foo/github_repo]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar,foo/github_repo]" RAILS_ENV=production
```
