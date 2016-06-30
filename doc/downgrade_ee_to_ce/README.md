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

### Git Annex

Git Annex is also only available on the Enterprise Edition. This means that if
you have repositories that use Git Annex to store large files, these files will
no longer be easily available via Git. You should consider migrating these
repositories to use Git LFS before downgrading to the Community Edition.

### Remove Jenkins CI Service entries from the database

The `JenkinsService` class is only available on the Enterprise Edition codebase,
so if you downgrade to the Community Edition, you'll come across the following
error:

```
Completed 500 Internal Server Error in 497ms (ActiveRecord: 32.2ms)

ActionView::Template::Error (The single-table inheritance mechanism failed to locate the subclass: 'JenkinsService'. This
error is raised because the column 'type' is reserved for storing the class in case of inheritance. Please rename this
column if you didn't intend it to be used for storing the inheritance class or overwrite Service.inheritance_column to
use another column for that information.)
```

All services are created automatically for every project you have, so in order
to avoid getting this error, you need to remove all instances of the
`JenkinsService` from your database:

**Omnibus Installation**

```
$ sudo gitlab-rails runner "Service.where(type: ['JenkinsService', 'JenkinsDeprecatedService']).delete_all"
```

**Source Installation**

```
$ bundle exec rails runner "Service.where(type: ['JenkinsService', 'JenkinsDeprecatedService']).delete_all" production
```

## Downgrade to CE

After performing the above mentioned steps, you are now ready to downgrade your
GitLab installation to the Community Edition.

**Omnibus Installation**

To downgrade an Omnibus installation, it is sufficient to install the Community
Edition package on top of the currently installed one. You can do this manually,
by directly [downloading the package](https://packages.gitlab.com/gitlab/gitlab-ce)
you need, or by adding our CE package repository and following the
[CE installation instructions](https://about.gitlab.com/downloads/).

**Source Installation**

To downgrade a source installation, you need to replace the current remote of
your GitLab installation with the Community Edition's remote, fetch the latest
changes, and checkout the latest stable branch:

```
$ git remote set-url origin git@gitlab.com:gitlab-org/gitlab-ce.git
$ git fetch --all
$ git checkout 8-x-stable
```

Remember to follow the correct [update guides](../update/README.md) to make
sure all dependencies are up to date.
