Depending on the installation method and your GitLab version, there are multiple update guides. Choose one that fits your needs.

## CE to EE

- [The CE to EE update guides](https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc/update) the steps are very similar to a version upgrade: stop the server, get the code, update config files for the new functionality, install libs and do migrations, update the init script, start the application and check the application status.

## EE to CE

- If you need to downgrade your EE installation back to CE, you can follow [this guide](../downgrade_ee_to_ce/README.md) to make
the process as smooth as possible.

## Omnibus Packages

- [Omnibus update guide](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update.md) contains the steps needed to update a GitLab [package](https://about.gitlab.com/downloads/).

## Installation from source

- [The individual upgrade guides](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update) are for those who have installed GitLab from source.
- [The CE to EE update guides](https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc/update). The steps are very similar to a version upgrade: stop the server, get the code, update config files for the new functionality, install libs and do migrations, update the init script, start the application and check the application status.
- [Upgrader](upgrader.md) is an automatic ruby script that performs the update for installations from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a patch version, eg. 6.2.0 to 6.2.1.

## Miscellaneous

- [MySQL to PostgreSQL](mysql_to_postgresql.md) guides you through migrating your database from MySQL to PostgreSQL.
- [MySQL installation guide](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/database_mysql.md) contains additional information about configuring GitLab to work with a MySQL database.
- [Restoring from backup after a failed upgrade](restore_after_failure.md)
