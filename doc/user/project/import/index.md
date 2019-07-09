# Migrating projects to a GitLab instance

1. [From Bitbucket Cloud (aka bitbucket.org)](bitbucket.md)
1. [From Bitbucket Server (aka Stash)](bitbucket_server.md)
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
1. [By uploading a manifest file (AOSP)](manifest.md)
1. [From Gemnasium](gemnasium.md)
1. [From Phabricator](phabricator.md)

In addition to the specific migration documentation above, you can import any
Git repository via HTTP from the New Project page. Be aware that if the
repository is too large the import can timeout.

There is also the option of [connecting your external repository to get CI/CD benefits](../../../ci/ci_cd_for_external_repos/index.md). **(PREMIUM)**

## Migrating from self-hosted GitLab to GitLab.com

If you only need to migrate git repos, you can [import each project by URL](repo_by_url.md), but issues and merge requests can't be imported.

If you want to retain all metadata like issues and merge requests, you can use
the [import/export feature](../settings/import_export.md) to export projects from self-hosted GitLab and import those projects into GitLab.com.

NOTE: **Note:**
This approach assumes all users from the self-hosted instance have already been migrated.
If the users haven't been migrated yet, the user conducting the import
will take the place of all references to the missing user(s).

If you need to migrate all data over, you can leverage our [api](../../../api/README.md) to migrate from self-hosted to GitLab.com. 
The order of assets to migrate from a self-hosted instance to GitLab is the following:

1. [Users](../../../api/users.md)
1. [Groups](../../../api/groups.md)
1. [Projects](../../../api/projects.md)
1. [Project variables](../../../api/project_level_variables.md)

Keep in mind the limitations of the [import/export feature](../settings/import_export.md#exported-contents).

You will still need to migrate your Container Registry over a series of
Docker pulls and pushes and re-run any CI pipelines to retrieve any build artifacts.

## Migrating between two self-hosted GitLab instances

The best method for migrating a project from one GitLab instance to another,
perhaps from an old server to a new server for example, is to
[back up the project](../../../raketasks/backup_restore.md),
then restore it on the new server.

In the event of merging two GitLab instances together (for example, both instances have existing data on them and one can't be wiped), 
refer to the instructions in [Migrating from self-hosted GitLab to GitLab.com](#migrating-from-self-hosted-gitlab-to-gitlabcom).
