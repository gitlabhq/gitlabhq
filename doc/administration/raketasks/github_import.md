# GitHub import

> [Introduced]( https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10308) in GitLab 9.1.

In order to retrieve and import GitHub repositories, you will need a
[GitHub personal access token](https://github.com/settings/tokens).
A username should be passed as the second argument to the rake task
which will become the owner of the project. You can resume an import
with the same command.

Bear in mind that the syntax is very specific. Remove any spaces within the argument block and
before/after the brackets. Also, Some shells (e.g., zsh) can interpret the open/close brackets
(`[]`) separately. You may need to either escape the brackets or use double quotes.

## Importing multiple projects

To import a project from the list of your GitHub projects available:

```bash
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar]" RAILS_ENV=production
```

In this case, `access_token` is your GitHub personal access token, `root`
is your GitLab username, and  `foo/bar` is the new GitLab namespace/project that
will get created from your GitHub project. Subgroups are also possible: `foo/foo/bar`.

## Importing a single project

To import a specific GitHub project (named `foo/github_repo` here):

```bash
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar,foo/github_repo]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar,foo/github_repo]" RAILS_ENV=production
```
