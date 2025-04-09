---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab provides [Rake](https://ruby.github.io/rake/) tasks to assist you with common administration and operational
processes.

You can perform GitLab Rake tasks by using:

- `gitlab-rake <raketask>` for [Linux package](https://docs.gitlab.com/omnibus/) and [GitLab Helm chart](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information) installations.
- `bundle exec rake <raketask>` for [self-compiled](../../install/installation.md) installations.

## Available Rake tasks

The following Rake tasks are available for use with GitLab:

| Tasks                                                                                                      | Description |
|:-----------------------------------------------------------------------------------------------------------|:------------|
| [Access token expiration tasks](tokens/_index.md)                                                          | Bulk extend or remove expiration dates for access tokens. |
| [Back up and restore](../../administration/backup_restore/_index.md)                                          | Back up, restore, and migrate GitLab instances between servers. |
| [Clean up](cleanup.md)                                                                                     | Clean up unneeded items from GitLab instances. |
| [Development](../../development/rake_tasks.md)                                                                | Tasks for GitLab contributors. |
| [Elasticsearch](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)         | Maintain Elasticsearch in a GitLab instance. |
| [General maintenance](maintenance.md)                                                                      | General maintenance and self-check tasks. |
| [GitHub import](github_import.md)                                                                          | Retrieve and import repositories from GitHub. |
| [Import large project exports](project_import_export.md#import-large-projects)                             | Import large GitLab [project exports](../../user/project/settings/import_export.md). |
| [Incoming email](incoming_email.md)                                                                        | Incoming email-related tasks. |
| [Integrity checks](check.md)                                                                               | Check the integrity of repositories, files, LDAP, and more. |
| [LDAP maintenance](ldap.md)                                                                                | [LDAP](../../administration/auth/ldap/_index.md)-related tasks. |
| [Password](password.md)                                                                                    | Password management tasks. |
| [Praefect Rake tasks](praefect.md)                                                                         | [Praefect](../../administration/gitaly/praefect.md)-related tasks. |
| [Project import/export](project_import_export.md)                                                          | Prepare for [project exports and imports](../../user/project/settings/import_export.md). |
| [Sidekiq job migration](../sidekiq/sidekiq_job_migration.md)                                                          | Migrate Sidekiq jobs scheduled for future dates to a new queue. |
| [Service Desk email](service_desk_email.md)                                                                | Service Desk email-related tasks. |
| [SMTP maintenance](smtp.md)                                                                                | SMTP-related tasks. |
| [SPDX license list import](spdx.md)                                                                        | Import a local copy of the [SPDX license list](https://spdx.org/licenses/) for matching [License approval policies](../../user/compliance/license_approval_policies.md). |
| [Reset user passwords](../../security/reset_user_password.md#use-a-rake-task)                                 | Reset user passwords using Rake. |
| [Uploads migrate](uploads/migrate.md)                                                                      | Migrate uploads between local storage and object storage. |
| [Uploads sanitize](uploads/sanitize.md)                                                                    | Remove EXIF data from images uploaded to earlier versions of GitLab. |
| [Service Data](../../development/internal_analytics/service_ping/troubleshooting.md#generate-service-ping)    | Generate and troubleshoot [Service Ping](../../development/internal_analytics/service_ping/_index.md). |
| [User management](user_management.md)                                                                      | Perform user management tasks. |
| [Webhook administration](web_hooks.md)                                                                     | Maintain project webhooks. |
| [X.509 signatures](x509_signatures.md)                                                                     | Update X.509 commit signatures, which can be useful if the certificate store changed. |

To list all available Rake tasks:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

```shell
gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake -vT RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}
