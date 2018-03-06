# GitHub import

>**Note:**
>
>  - [Introduced][ce-10308] in GitLab 9.1.
>  - You need a personal access token in order to retrieve and import GitHub
>    projects. You can get it from: https://github.com/settings/tokens
>  - You also need to pass an username as the second argument to the rake task
>    which will become the owner of the project.
>  - You can also resume an import with the same command.

To import a project from the list of your GitHub projects available:

```bash
# Omnibus installations
sudo gitlab-rake import:github[access_token,root,foo/bar]

# Installations from source
bundle exec rake import:github[access_token,root,foo/bar] RAILS_ENV=production
```

In this case, `access_token` is your GitHub personal access token, `root`
is your GitLab username, and  `foo/bar` is the new GitLab namespace/project that
will get created from your GitHub project. Subgroups are also possible: `foo/foo/bar`.


To import a specific GitHub project (named `foo/github_repo` here):

```bash
# Omnibus installations
sudo gitlab-rake import:github[access_token,root,foo/bar,foo/github_repo]

# Installations from source
bundle exec rake import:github[access_token,root,foo/bar,foo/github_repo] RAILS_ENV=production
```

[ce-10308]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10308



## Troubleshooting

* Syntax is very specific. Remove spaces within argument block and prior to brackets

```
# Success
sudo gitlab-rake import:github[access_token,root,foo/bar]

# Fail
sudo gitlab-rake import:github[access_token, root, foo/bar]
rake aborted!
Don't know how to build task 'import:github[access_token, root, foo/bar,' (see --tasks)
```

* Some shells can interpret the open/close brackets (`[]`) separately (ex: zsh). You may need to escape the brackets or switch shells

```
zsh: no matches found: import:github[token,root,foo/project,group/repository]
```
