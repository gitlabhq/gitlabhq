# Migrating projects to a GitLab instance

1. [Bitbucket](import_projects_from_bitbucket.md)
1. [GitHub](import_projects_from_github.md)
1. [GitLab.com](import_projects_from_gitlab_com.md)
1. [FogBugz](import_projects_from_fogbugz.md)
1. [Gitea](import_projects_from_gitea.md)
1. [SVN](migrating_from_svn.md)

In addition to the specific migration documentation above, you can import any
Git repository via HTTP from the New Project page. Be aware that if the
repository is too large the import can timeout.

### Migrating from self-hosted GitLab to GitLab.com

You can copy your repos by changing the remote and pushing to the new server;
but issues and merge requests can't be imported.

### Troubleshooting Migration issues.

You'll need admin access to the Gitlab Instance. You can run the following commands:

```
gitlab-rails console production
project = Project.find_with_namespace('group/user/project')
project.import_error
# If you are confident that the errors are minor, you could manually finish the import
# This could have unintended side effects, so work to fix the import errors before trying this.
project.import_finish

```

This output will let you know what was causing the errors for the import 
so that you can correct them.