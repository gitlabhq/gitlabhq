---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrating projects to a GitLab instance

1. [From Bitbucket Cloud](bitbucket.md)
1. [From Bitbucket Server (also known as Stash)](bitbucket_server.md)
1. [From ClearCase](clearcase.md)
1. [From CVS](cvs.md)
1. [From FogBugz](fogbugz.md)
1. [From GitHub.com or GitHub Enterprise](github.md)
1. [From GitLab.com](gitlab_com.md)
1. [From Gitea](gitea.md)
1. [From Perforce](perforce.md)
1. [From SVN](svn.md)
1. [From TFVC](tfvc.md)
1. [From repository by URL](repo_by_url.md)
1. [By uploading a manifest file (AOSP)](manifest.md)
1. [From Gemnasium](gemnasium.md)
1. [From Phabricator](phabricator.md)
1. [From Jira (issues only)](jira.md)

In addition to the specific migration documentation above, you can import any
Git repository via HTTP from the New Project page. Be aware that if the
repository is too large the import can timeout.

There is also the option of [connecting your external repository to get CI/CD benefits](../../../ci/ci_cd_for_external_repos/index.md). **(PREMIUM)**

## LFS authentication

When importing a project that contains LFS objects, if the project has an [`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/master/docs/man/git-lfs-config.5.ronn)
file with a URL host (`lfs.url`) different from the repository URL host, LFS files are not downloaded.

## Migrating from self-managed GitLab to GitLab.com

If you only need to migrate Git repositories, you can [import each project by URL](repo_by_url.md). Issues and merge requests can't be imported.

If you want to retain all metadata like issues and merge requests, you can use
the [import/export feature](../settings/import_export.md) to export projects from self-managed GitLab and import those projects into GitLab.com.

All GitLab user associations (such as comment author) will be changed to the user importing the project. For more information, please see [the import notes](../settings/import_export.md#important-notes).

If you need to migrate all data over, you can leverage our [API](../../../api/README.md) to migrate from self-managed to GitLab.com.
The order of assets to migrate from a self-managed instance to GitLab.com is the following:

NOTE: **Note:**
When migrating to GitLab.com, users would need to be manually created unless [SCIM](../../../user/group/saml_sso/scim_setup.md) is going to be used. Creating users with the API is limited to self-managed instances as it requires administrator access.

1. [Groups](../../../api/groups.md)
1. [Projects](../../../api/projects.md)
1. [Project variables](../../../api/project_level_variables.md)

Keep in mind the limitations of the [import/export feature](../settings/import_export.md#exported-contents).

You will still need to migrate your Container Registry over a series of
Docker pulls and pushes and re-run any CI pipelines to retrieve any build artifacts.

## Migrating from GitLab.com to self-managed GitLab

The process is essentially the same as for [migrating from self-managed GitLab to GitLab.com](#migrating-from-self-managed-gitlab-to-gitlabcom). The main difference is that users can be created on the self-managed GitLab instance by an admin through the UI or the [users API](../../../api/users.md#user-creation).

## Migrating between two self-managed GitLab instances

The best method for migrating from one GitLab instance to another,
perhaps from an old server to a new server for example, is to
[back up the instance](../../../raketasks/backup_restore.md),
then restore it on the new server.

In the event of merging two GitLab instances together (for example, both instances have existing data on them and one can't be wiped),
refer to the instructions in [Migrating from self-managed GitLab to GitLab.com](#migrating-from-self-managed-gitlab-to-gitlabcom).

Additionally, you can migrate users using the [Users API](../../../api/users.md) with an admin user.
