---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Downgrading from EE to CE

If you ever decide to downgrade your Enterprise Edition back to the Community
Edition, there are a few steps you need take before installing the CE package
on top of the current EE package, or, if you are in an installation from source,
before you change remotes and fetch the latest CE code.

## Disable Enterprise-only features

First thing to do is to disable the following features.

### Authentication mechanisms

Kerberos and Atlassian Crowd are only available on the Enterprise Edition, so
you should disable these mechanisms before downgrading and you should provide
alternative authentication methods to your users.

### Remove Service Integration entries from the database

The GitHub integration is only available in the Enterprise Edition codebase,
so if you downgrade to the Community Edition, the following error displays:

```plaintext
Completed 500 Internal Server Error in 497ms (ActiveRecord: 32.2ms)

ActionView::Template::Error (The single-table inheritance mechanism failed to locate the subclass: 'GithubService'. This
error is raised because the column 'type' is reserved for storing the class in case of inheritance. Please rename this
column if you didn't intend it to be used for storing the inheritance class or overwrite Integration.inheritance_column to
use another column for that information.)
```

All integrations are created automatically for every project you have, so in order
to avoid getting this error, you need to remove all records with the type set to
`GithubService` from your database:

**Omnibus Installation**

```shell
sudo gitlab-rails runner "Integration.where(type: ['GithubService']).delete_all"
```

**Source Installation**

```shell
bundle exec rails runner "Integration.where(type: ['GithubService']).delete_all" production
```

NOTE:
If you are running `GitLab =< v13.0` you need to also remove `JenkinsDeprecatedService` records
and if you are running `GitLab =< v13.6` you need to also remove `JenkinsService` records.

### Variables environment scopes

If you're using this feature and there are variables sharing the same
key, but they have different scopes in a project, then you might want to
revisit the environment scope setting for those variables.

In CE, environment scopes are completely ignored, therefore you could
accidentally get a variable which you're not expecting for a particular
environment. Make sure that you have the right variables in this case.

Data is completely preserved, so you could always upgrade back to EE and
restore the behavior if you leave it alone.

## Downgrade to CE

After performing the above mentioned steps, you are now ready to downgrade your
GitLab installation to the Community Edition.

**Omnibus Installation**

To downgrade an Omnibus installation, it is sufficient to install the Community
Edition package on top of the currently installed one. You can do this manually,
by directly [downloading the package](https://packages.gitlab.com/gitlab/gitlab-ce)
you need, or by adding our CE package repository and following the
[CE installation instructions](https://about.gitlab.com/install/?version=ce).

**Source Installation**

To downgrade a source installation, you need to replace the current remote of
your GitLab installation with the Community Edition's remote, fetch the latest
changes, and checkout the latest stable branch:

```shell
git remote set-url origin git@gitlab.com:gitlab-org/gitlab-foss.git
git fetch --all
git checkout 8-x-stable
```

Remember to follow the correct [update guides](../update/index.md) to make
sure all dependencies are up to date.
