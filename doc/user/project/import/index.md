# Migrating projects to a GitLab instance

1. [From Bitbucket.org](bitbucket.md)
1. [From ClearCase](clearcase.md)
1. [From CVS](cvs.md)
1. [From FogBugz](fogbugz.md)
1. [From GitHub.com or GitHub Enterprise](github.md)
1. [From GitLab.com](gitlab_com.md)
1. [From Gitea](gitea.md)
1. [From Perforce](perforce.md)
1. [From SVN](svn.md)
1. [From TFS](tfs.md)
1. [From repo by URL](repo_by_url.md)

In addition to the specific migration documentation above, you can import any
Git repository via HTTP from the New Project page. Be aware that if the
repository is too large the import can timeout.

## Migrating from self-hosted GitLab to GitLab.com

You can copy your repos by changing the remote and pushing to the new server,
but issues and merge requests can't be imported.

If you want to retain all metadata like issues and merge requests, you can use
the [import/export feature](../settings/import_export.md).
