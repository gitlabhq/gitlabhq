# Updating GitLab

Depending on the installation method and your GitLab version, there are multiple
update guides.

There are currently 3 official ways to install GitLab:

- Omnibus packages
- Source installation
- Docker installation

Based on your installation, choose a section below that fits your needs.

## Omnibus Packages

- The [Omnibus update guide](http://docs.gitlab.com/omnibus/update/README.html)
  contains the steps needed to update an Omnibus GitLab package.

## Installation from source

- [Upgrading Community Edition from source][source-ce] - The individual
  upgrade guides are for those who have installed GitLab CE from source.
- [Upgrading Enterprise Edition from source][source-ee] - The individual
  upgrade guides are for those who have installed GitLab EE from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a
  patch version, eg. 6.2.0 to 6.2.1, and apply to both Community and Enterprise
  Editions.

## Installation using Docker

GitLab provides official Docker images for both Community and Enterprise
editions. They are based on the Omnibus package and instructions on how to
update them are in [a separate document][omnidocker].

## Upgrading without downtime

Starting with GitLab 9.1.0 it's possible to upgrade to a newer major, minor, or
patch version of GitLab without having to take your GitLab instance offline.
However, for this to work there are the following requirements:

1. You can only upgrade 1 minor release at a time. So from 9.1 to 9.2, not to
   9.3.
2. You have to use [post-deployment
   migrations](../development/post_deployment_migrations.md).
3. You are using PostgreSQL. If you are using MySQL please look at the release
   post to see if downtime is required.

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
`background_migration` queue.

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

- [Source CE to EE update guides][source-ee] - Find your version, and follow the
  `-ce-to-ee.md` guide. The steps are very similar to a version upgrade: stop
  the server, get the code, update config files for the new functionality,
  install libraries and do migrations, update the init script, start the
  application and check its status.
- [Omnibus CE to EE][omni-ce-ee] - Follow this guide to update your Omnibus
  GitLab Community Edition to the Enterprise Edition.

### Enterprise to Community Edition

If you need to downgrade your Enterprise Edition installation back to Community
Edition, you can follow [this guide][ee-ce] to make the process as smooth as
possible.

## Miscellaneous

- [MySQL to PostgreSQL](mysql_to_postgresql.md) guides you through migrating
  your database from MySQL to PostgreSQL.
- [MySQL installation guide](../install/database_mysql.md) contains additional
  information about configuring GitLab to work with a MySQL database.
- [Restoring from backup after a failed upgrade](restore_after_failure.md)
- [Upgrading PostgreSQL Using Slony](upgrading_postgresql_using_slony.md), for
  upgrading a PostgreSQL database with minimal downtime.

[omnidocker]: http://docs.gitlab.com/omnibus/docker/README.html
[source-ee]: https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc/update
[source-ce]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update
[ee-ce]: ../downgrade_ee_to_ce/README.md
[ce]: https://about.gitlab.com/features/#community
[ee]: https://about.gitlab.com/features/#enterprise
[omni-ce-ee]: http://docs.gitlab.com/omnibus/update/README.html#from-community-edition-to-enterprise-edition
