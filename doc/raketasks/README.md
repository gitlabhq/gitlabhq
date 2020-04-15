---
comments: false
---

# Rake tasks **(CORE ONLY)**

GitLab provides [Rake](https://ruby.github.io/rake/) tasks for common administration and operational processes.

GitLab Rake tasks are performed using:

- `gitlab-rake <raketask>` for [Omnibus GitLab](https://docs.gitlab.com/omnibus/README.html) installations.
- `bundle exec rake <raketask>` for [source](../install/installation.md) installations.

## Available Rake tasks

The following are available Rake tasks:

| Tasks                                                                                      | Description                                                                               |
|:-------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------|
| [Back up and restore](backup_restore.md)                                                   | Back up, restore, and migrate GitLab instances between servers.                           |
| [Clean up](cleanup.md)                                                                     | Clean up unneeded items GitLab instances.                                                 |
| [Development](../development/rake_tasks.md)                                                | Tasks for GitLab contributors.                                                            |
| [Elasticsearch](../integration/elasticsearch.md#gitlab-elasticsearch-rake-tasks)           | Maintain Elasticsearch in a GitLab instance.                                              |
| [Enable namespaces](features.md)                                                           | Enable usernames and namespaces for user projects.                                        |
| [General maintenance](../administration/raketasks/maintenance.md)                          | General maintenance and self-check tasks.                                                 |
| [Geo maintenance](../administration/raketasks/geo.md) **(PREMIUM ONLY)**                   | [Geo](../administration/geo/replication/index.md)-related maintenance.                    |
| [GitHub import](../administration/raketasks/github_import.md)                              | Retrieve and import repositories from GitHub.                                             |
| [Import repositories](import.md)                                                           | Import bare repositories into your GitLab instance.                                       |
| [Import large project exports](../development/import_project.md#importing-via-a-rake-task) | Import large GitLab [project exports](../user/project/settings/import_export.md).         |
| [Integrity checks](../administration/raketasks/check.md)                                   | Check the integrity of repositories, files, and LDAP.                                     |
| [LDAP maintenance](../administration/raketasks/ldap.md)                                    | [LDAP](../administration/auth/ldap.md)-related tasks.                                     |
| [List repositories](list_repos.md)                                                         | List of all GitLab-managed Git repositories on disk.                                      |
| [Project import/export](../administration/raketasks/project_import_export.md)              | Prepare for [project exports and imports](../user/project/settings/import_export.md).     |
| [Repository storage](../administration/raketasks/storage.md)                               | List and migrate existing projects and attachments from legacy storage to hashed storage. |
| [Uploads migrate](../administration/raketasks/uploads/migrate.md)                          | Migrate uploads between storage local and object storage.                                 |
| [Uploads sanitize](../administration/raketasks/uploads/sanitize.md)                        | Remove EXIF data from images uploaded to earlier versions of GitLab.                      |
| [User management](user_management.md)                                                      | Perform user management tasks.                                                            |
| [Webhooks administration](web_hooks.md)                                                    | Maintain project Webhooks.                                                                |
| [X509 signatures](x509_signatures.md)                                                      | Update x509 commit signatures, useful if certificate store has changed.                   |
