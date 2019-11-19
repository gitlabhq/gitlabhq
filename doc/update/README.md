# Updating GitLab

Depending on the installation method and your GitLab version, there are multiple
update guides.

There are currently 3 official ways to install GitLab:

- [Omnibus packages](#omnibus-packages)
- [Source installation](#installation-from-source)
- [Docker installation](#installation-using-docker)

Based on your installation, choose a section below that fits your needs.

## Omnibus Packages

- The [Omnibus update guide][omni-update]
  contains the steps needed to update an Omnibus GitLab package.

## Installation from source

- [Upgrading Community Edition and Enterprise Edition from
  source](upgrading_from_source.md) - The guidelines for upgrading Community
  Edition and Enterprise Edition from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a
  patch version, eg. 6.2.0 to 6.2.1, and apply to both Community and Enterprise
  Editions.

In the past we used separate documents for the upgrading instructions, but we
have since switched to using a single document. The old upgrading guidelines
can still be found in the Git repository:

- [Old upgrading guidelines for Community Edition][old-ce-upgrade-docs]
- [Old upgrading guidelines for Enterprise Edition][old-ee-upgrade-docs]

## Installation using Docker

GitLab provides official Docker images for both Community and Enterprise
editions. They are based on the Omnibus package and instructions on how to
update them are in [a separate document][omni-docker].

## Upgrading without downtime

Starting with GitLab 9.1.0 it's possible to upgrade to a newer major, minor, or
patch version of GitLab without having to take your GitLab instance offline.
However, for this to work there are the following requirements:

- You can only upgrade 1 minor release at a time. So from 9.1 to 9.2, not to
   9.3.
- You have to use [post-deployment
   migrations](../development/post_deployment_migrations.md) (included in
   zero downtime update steps below).
- You are using PostgreSQL. Starting from GitLab 12.1, MySQL is not supported.

Most of the time you can safely upgrade from a patch release to the next minor
release if the patch release is not the latest. For example, upgrading from
9.1.1 to 9.2.0 should be safe even if 9.1.2 has been released. We do recommend
you check the release posts of any releases between your current and target
version just in case they include any migrations that may require you to upgrade
1 release at a time.

Some releases may also include so called "background migrations". These
migrations are performed in the background by Sidekiq and are often used for
migrating data. Background migrations are only added in the monthly releases.

Certain major/minor releases may require a set of background migrations to be
finished. To guarantee this such a release will process any remaining jobs
before continuing the upgrading procedure. While this won't require downtime
(if the above conditions are met) we recommend users to keep at least 1 week
between upgrading major/minor releases, allowing the background migrations to
finish. The time necessary to complete these migrations can be reduced by
increasing the number of Sidekiq workers that can process jobs in the
`background_migration` queue. To check the size of this queue,
[start a Rails console session](https://docs.gitlab.com/omnibus/maintenance/#starting-a-rails-console-session)
and run the command below:

```ruby
Sidekiq::Queue.new('background_migration').size
```

As a rule of thumb, any database smaller than 10 GB won't take too much time to
upgrade; perhaps an hour at most per minor release. Larger databases however may
require more time, but this is highly dependent on the size of the database and
the migrations that are being performed.

### Examples

To help explain this, let's look at some examples.

**Example 1:** You are running a large GitLab installation using version 9.4.2,
which is the latest patch release of 9.4. When GitLab 9.5.0 is released this
installation can be safely upgraded to 9.5.0 without requiring downtime if the
requirements mentioned above are met. You can also skip 9.5.0 and upgrade to
9.5.1 once it's released, but you **can not** upgrade straight to 9.6.0; you
_have_ to first upgrade to a 9.5.x release.

**Example 2:** You are running a large GitLab installation using version 9.4.2,
which is the latest patch release of 9.4. GitLab 9.5 includes some background
migrations, and 10.0 will require these to be completed (processing any
remaining jobs for you). Skipping 9.5 is not possible without downtime, and due
to the background migrations would require potentially hours of downtime
depending on how long it takes for the background migrations to complete. To
work around this you will have to upgrade to 9.5.x first, then wait at least a
week before upgrading to 10.0.

**Example 3:** You use MySQL as the database for GitLab. Any upgrade to a new
major/minor release will require downtime. If a release includes any background
migrations this could potentially lead to hours of downtime, depending on the
size of your database. To work around this you will have to use PostgreSQL and
meet the other online upgrade requirements mentioned above.

### Steps

Steps to [upgrade without downtime][omni-zero-downtime].

## Upgrading between editions

GitLab comes in two flavors: [Community Edition][ce] which is MIT licensed,
and [Enterprise Edition][ee] which builds on top of the Community Edition and
includes extra features mainly aimed at organizations with more than 100 users.

Below you can find some guides to help you change editions easily.

### Community to Enterprise Edition

>**Note:**
The following guides are for subscribers of the Enterprise Edition only.

If you wish to upgrade your GitLab installation from Community to Enterprise
Edition, follow the guides below based on the installation method:

- [Source CE to EE update guides][source-ce-to-ee] - The steps are very similar
  to a version upgrade: stop the server, get the code, update config files for
  the new functionality, install libraries and do migrations, update the init
  script, start the application and check its status.
- [Omnibus CE to EE][omni-ce-ee] - Follow this guide to update your Omnibus
  GitLab Community Edition to the Enterprise Edition.

### Enterprise to Community Edition

If you need to downgrade your Enterprise Edition installation back to Community
Edition, you can follow [this guide][ee-ce] to make the process as smooth as
possible.

## Version specific upgrading instructions

### 12.2.0

In 12.2.0, we enabled Rails' authenticated cookie encryption. Old sessions are
automatically upgraded.

However, session cookie downgrades are not supported. So after upgrading to 12.2.0,
any downgrades would result to all sessions being invalidated and users are logged out.

### 12.0.0

In 12.0.0 we made various database related changes. These changes require that
users first upgrade to the latest 11.11 patch release. Once upgraded to 11.11.x,
users can upgrade to 12.x. Failure to do so may result in database migrations
not being applied, which could lead to application errors.

Example 1: you are currently using GitLab 11.11.3, which is the latest patch
release for 11.11.x. You can upgrade as usual to 12.0.0, 12.1.0, etc.

Example 2: you are currently using a version of GitLab 10.x. To upgrade, first
upgrade to 11.11.3. Once upgraded to 11.11.3 you can safely upgrade to 12.0.0
or future versions.

## Miscellaneous

- [MySQL to PostgreSQL](mysql_to_postgresql.md) guides you through migrating
  your database from MySQL to PostgreSQL.
- [Restoring from backup after a failed upgrade](restore_after_failure.md)
- [Upgrading PostgreSQL Using Slony](upgrading_postgresql_using_slony.md), for
  upgrading a PostgreSQL database with minimal downtime.

[omnidocker]: https://docs.gitlab.com/omnibus/docker/README.html
[old-ee-upgrade-docs]: https://gitlab.com/gitlab-org/gitlab/tree/11-8-stable-ee/doc/update
[old-ce-upgrade-docs]: https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update
[source-ce-to-ee]: upgrading_from_ce_to_ee.md
[ee-ce]: ../downgrade_ee_to_ce/README.md
[ce]: https://about.gitlab.com/features/#community
[ee]: https://about.gitlab.com/features/#enterprise
[omni-ce-ee]: https://docs.gitlab.com/omnibus/update/README.html#updating-community-edition-to-enterprise-edition
[omni-docker]: https://docs.gitlab.com/omnibus/docker/README.html
[omni-update]: https://docs.gitlab.com/omnibus/update/README.html
[omni-zero-downtime]: https://docs.gitlab.com/omnibus/update/README.html#zero-downtime-updates
