# Updating GitLab

Depending on the installation method and your GitLab version, there are multiple
update guides.

There are currently 3 official ways to install GitLab:

- Omnibus packages
- Source installation
- Docker installation

Based on your installation, choose a section below that fits your needs.

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Omnibus Packages](#omnibus-packages)
- [Installation from source](#installation-from-source)
- [Installation using Docker](#installation-using-docker)
- [Upgrading between editions](#upgrading-between-editions)
    - [Community to Enterprise Edition](#community-to-enterprise-edition)
    - [Enterprise to Community Edition](#enterprise-to-community-edition)
- [Miscellaneous](#miscellaneous)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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

[omnidocker]: http://docs.gitlab.com/omnibus/docker/README.html
[source-ee]: https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc/update
[source-ce]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update
[ee-ce]: ../downgrade_ee_to_ce/README.md
[ce]: https://about.gitlab.com/features/#community
[ee]: https://about.gitlab.com/features/#enterprise
[omni-ce-ee]: http://docs.gitlab.com/omnibus/update/README.html#from-community-edition-to-enterprise-edition
