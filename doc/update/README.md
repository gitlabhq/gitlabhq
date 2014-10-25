Depending on the installation method and your GitLab version, there are multiple update guides. Choose one that fits your needs.

## Omnibus Packages

- [Omnibus update guide](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update.md) contains the steps needed to update a GitLab [package](https://about.gitlab.com/downloads/).

## Manual Installation

- [The individual upgrade guides](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update) are for those who have installed GitLab manually.
- [The CE to EE update guides](https://gitlab.com/subscribers/gitlab-ee/tree/master/doc/update) are for subscribers of the Enterprise Edition only. The steps are very similar to a version upgrade: stop the server, get the code, update config files for the new functionality, install libs and do migrations, update the init script, start the application and check the application status.
- [Upgrader](upgrader.md) is an automatic ruby script that performs the update for manual installations.
- [Patch versions](patch_versions.md) guide includes the steps needed for a patch version, eg. 6.2.0 to 6.2.1.

## Miscellaneous

- [MySQL to PostgreSQL](mysql_to_postgresql.md) guides you through migrating your database from MySQL to PostrgreSQL.
