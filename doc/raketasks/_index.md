---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides [Rake](https://ruby.github.io/rake/) tasks to assist you with common administration and operational
processes.

You can perform GitLab Rake tasks by using:

- `gitlab-rake <raketask>` for [Linux package](https://docs.gitlab.com/omnibus/index.html) and [GitLab Helm chart](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information) installations.
- `bundle exec rake <raketask>` for [self-compiled](../install/installation.md) installations.

## Available Rake tasks

The following Rake tasks are available for use with GitLab:

| Tasks                                                                                                      | Description |
|:-----------------------------------------------------------------------------------------------------------|:------------|
| [Access token expiration tasks](../administration/raketasks/tokens/_index.md)                               | Bulk extend or remove expiration dates for access tokens. |
| [Back up and restore](../administration/backup_restore/_index.md)                                           | Back up, restore, and migrate GitLab instances between servers. |
| [Clean up](cleanup.md)                                                                                     | Clean up unneeded items from GitLab instances. |
| [Development](../development/rake_tasks.md)                                                                | Tasks for GitLab contributors. |
| [Elasticsearch](../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)         | Maintain Elasticsearch in a GitLab instance. |
| [General maintenance](../administration/raketasks/maintenance.md)                                          | General maintenance and self-check tasks. |
| [GitHub import](../administration/raketasks/github_import.md)                                              | Retrieve and import repositories from GitHub. |
| [Import large project exports](../administration/raketasks/project_import_export.md#import-large-projects) | Import large GitLab [project exports](../user/project/settings/import_export.md). |
| [Incoming email](../administration/raketasks/incoming_email.md)                                            | Incoming email-related tasks. |
| [Integrity checks](../administration/raketasks/check.md)                                                   | Check the integrity of repositories, files, LDAP, and more. |
| [LDAP maintenance](../administration/raketasks/ldap.md)                                                    | [LDAP](../administration/auth/ldap/_index.md)-related tasks. |
| [Praefect Rake tasks](../administration/raketasks/praefect.md)                                             | [Praefect](../administration/gitaly/praefect.md)-related tasks. |
| [Project import/export](../administration/raketasks/project_import_export.md)                              | Prepare for [project exports and imports](../user/project/settings/import_export.md). |
| [Sidekiq job migration](../administration/sidekiq/sidekiq_job_migration.md)                                | Migrate Sidekiq jobs scheduled for future dates to a new queue. |
| [Service Desk email](../administration/raketasks/service_desk_email.md)                                    | Service Desk email-related tasks. |
| [SMTP maintenance](../administration/raketasks/smtp.md)                                                    | SMTP-related tasks. |
| [SPDX license list import](spdx.md)                                                                        | Import a local copy of the [SPDX license list](https://spdx.org/licenses/) for matching [License approval policies](../user/compliance/license_approval_policies.md). |
| [Reset user passwords](../security/reset_user_password.md#use-a-rake-task)                                 | Reset user passwords using Rake. |
| [Uploads migrate](../administration/raketasks/uploads/migrate.md)                                          | Migrate uploads between local storage and object storage. |
| [Uploads sanitize](../administration/raketasks/uploads/sanitize.md)                                        | Remove EXIF data from images uploaded to earlier versions of GitLab. |
| [Service Data](../development/internal_analytics/service_ping/troubleshooting.md#generate-service-ping)    | Generate and troubleshoot [Service Ping](../development/internal_analytics/service_ping/_index.md). |
| [User management](user_management.md)                                                                      | Perform user management tasks. |
| [Webhook administration](web_hooks.md)                                                                     | Maintain project webhooks. |
| [X.509 signatures](x509_signatures.md)                                                                     | Update X.509 commit signatures, which can be useful if the certificate store changed. |

To list all available Rake tasks:

```shell
# Omnibus GitLab
sudo gitlab-rake -vT

# GitLab Helm chart
gitlab-rake -vT

# Installations from source
cd /home/git/gitlab
sudo -u git -H bundle exec rake -vT RAILS_ENV=production
```
