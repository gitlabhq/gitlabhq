---
description: 'Learn how to install, configure, update, and maintain your GitLab instance.'
---

# Administrator Docs **(CORE ONLY)**

Learn how to administer your self-managed GitLab instance.

GitLab has two product distributions available through [different subscriptions](https://about.gitlab.com/pricing/):

- The open source [GitLab Community Edition (CE)](https://gitlab.com/gitlab-org/gitlab-foss).
- The open core [GitLab Enterprise Edition (EE)](https://gitlab.com/gitlab-org/gitlab).

You can [install either GitLab CE or GitLab EE](https://about.gitlab.com/install/ce-or-ee/).
However, the features you'll have access to depend on the subscription you choose
(Core, Starter, Premium, or Ultimate).

NOTE: **Note:**
GitLab Community Edition installations only have access to Core features.

GitLab.com is administered by GitLab, Inc., therefore, only GitLab team members have
access to its admin configurations. If you're a GitLab.com user, please check the
[user documentation](../user/index.md).

NOTE: **Note:**
Non-administrator users don’t have access to GitLab administration tools and settings.

## Installing and maintaining GitLab

Learn how to install, configure, update, and maintain your GitLab instance.

### Installing GitLab

- [Install](../install/README.md): Requirements, directory structures, and installation methods.
  - [Database load balancing](database_load_balancing.md): Distribute database queries among multiple database servers. **(STARTER ONLY)**
  - [Omnibus support for log forwarding](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only) **(STARTER ONLY)**
- [High Availability](high_availability/README.md): Configure multiple servers for scaling or high availability.
  - [Installing GitLab HA on Amazon Web Services (AWS)](../install/aws/index.md): Set up GitLab High Availability on Amazon AWS.
- [Geo](geo/replication/index.md): Replicate your GitLab instance to other geographic locations as a read-only fully operational version. **(PREMIUM ONLY)**
- [Disaster Recovery](geo/disaster_recovery/index.md): Quickly fail-over to a different site with minimal effort in a disaster situation. **(PREMIUM ONLY)**
- [Pivotal Tile](../install/pivotal/index.md): Deploy GitLab as a pre-configured appliance using Ops Manager (BOSH) for Pivotal Cloud Foundry. **(PREMIUM ONLY)**
- [Add License](../user/admin_area/license.md): Upload a license at install time to unlock features that are in paid tiers of GitLab. **(STARTER ONLY)**

### Configuring GitLab

- [Adjust your instance's timezone](timezone.md): Customize the default time zone of GitLab.
- [System hooks](../system_hooks/system_hooks.md): Notifications when users, projects and keys are changed.
- [Security](../security/README.md): Learn what you can do to further secure your GitLab instance.
- [Usage statistics, version check, and usage ping](../user/admin_area/settings/usage_statistics.md): Enable or disable information about your instance to be sent to GitLab, Inc.
- [Global user settings](user_settings.md): Configure instance-wide user permissions.
- [Polling](polling.md): Configure how often the GitLab UI polls for updates.
- [GitLab Pages configuration](pages/index.md): Enable and configure GitLab Pages.
- [GitLab Pages configuration for GitLab source installations](pages/source.md): Enable and configure GitLab Pages on [source installations](../install/installation.md#installation-from-source).
- [Uploads administration](uploads.md): Configure GitLab uploads storage.
- [Environment variables](environment_variables.md): Supported environment variables that can be used to override their defaults values in order to configure GitLab.
- [Plugins](plugins.md): With custom plugins, GitLab administrators can introduce custom integrations without modifying GitLab's source code.
- [Enforcing Terms of Service](../user/admin_area/settings/terms.md)
- [Third party offers](../user/admin_area/settings/third_party_offers.md)
- [Compliance](compliance.md): A collection of features from across the application that you may configure to help ensure that your GitLab instance and DevOps workflow meet compliance standards.
- [Diff limits](../user/admin_area/diff_limits.md): Configure the diff rendering size limits of branch comparison pages.
- [Merge request diffs storage](merge_request_diffs.md): Configure merge requests diffs external storage.
- [Broadcast Messages](../user/admin_area/broadcast_messages.md): Send messages to GitLab users through the UI.
- [Elasticsearch](../integration/elasticsearch.md): Enable Elasticsearch to empower GitLab's Advanced Global Search. Useful when you deal with a huge amount of data. **(STARTER ONLY)**
- [External Classification Policy Authorization](../user/admin_area/settings/external_authorization.md) **(PREMIUM ONLY)**
- [Upload a license](../user/admin_area/license.md): Upload a license to unlock features that are in paid tiers of GitLab. **(STARTER ONLY)**
- [Admin Area](../user/admin_area/index.md): for self-managed instance-wide configuration and maintenance.
- [S/MIME Signing](smime_signing_email.md): how to sign all outgoing notification emails with S/MIME

#### Customizing GitLab's appearance

- [Header logo](../user/admin_area/appearance.md#navigation-bar): Change the logo on all pages and email headers.
- [Favicon](../user/admin_area/appearance.md#favicon): Change the default favicon to your own logo.
- [Branded login page](../user/admin_area/appearance.md#sign-in--sign-up-pages): Customize the login page with your own logo, title, and description.
- ["New Project" page](../user/admin_area/appearance.md#new-project-pages): Customize the text to be displayed on the page that opens whenever your users create a new project.
- [Additional custom email text](../user/admin_area/settings/email.md#custom-additional-text-premium-only): Add additional custom text to emails sent from GitLab. **(PREMIUM ONLY)**

### Maintaining GitLab

- [Raketasks](../raketasks/README.md): Perform various tasks for maintenance, backups, automatic webhooks setup, etc.
  - [Backup and restore](../raketasks/backup_restore.md): Backup and restore your GitLab instance.
- [Operations](operations/index.md): Keeping GitLab up and running (clean up Redis sessions, moving repositories, Sidekiq MemoryKiller, Unicorn).
- [Restart GitLab](restart_gitlab.md): Learn how to restart GitLab and its components.
- [Invalidate Markdown cache](invalidate_markdown_cache.md): Invalidate any cached Markdown.

#### Updating GitLab

- [GitLab versions and maintenance policy](../policy/maintenance.md): Understand GitLab versions and releases (Major, Minor, Patch, Security), as well as update recommendations.
- [Update GitLab](../update/README.md): Update guides to upgrade your installation to a new version.
- [Downtimeless updates](../update/README.md#upgrading-without-downtime): Upgrade to a newer major, minor, or patch version of GitLab without taking your GitLab instance offline.
- [Migrate your GitLab CI/CD data to another version of GitLab](../migrate_ci_to_ce/README.md): If you have an old GitLab installation (older than 8.0), follow this guide to migrate your existing GitLab CI/CD data to another version of GitLab.

### Upgrading or downgrading GitLab

- [Upgrade from GitLab CE to GitLab EE](../update/README.md#upgrading-between-editions): learn how to upgrade GitLab Community Edition to GitLab Enterprise Editions.
- [Downgrade from GitLab EE to GitLab CE](../downgrade_ee_to_ce/README.md): Learn how to downgrade GitLab Enterprise Editions to Community Edition.

### GitLab platform integrations

- [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/): Integrate with [Mattermost](https://mattermost.com), an open source, private cloud workplace for web messaging.
- [PlantUML](integration/plantuml.md): Create simple diagrams in AsciiDoc and Markdown documents
  created in snippets, wikis, and repos.
- [Web terminals](integration/terminal.md): Provide terminal access to your applications deployed to Kubernetes from within GitLab's CI/CD [environments](../ci/environments.md#web-terminals).

## User settings and permissions

- [Creating users](../user/profile/account/create_accounts.md): Create users manually or through authentication integrations.
- [Libravatar](libravatar.md): Use Libravatar instead of Gravatar for user avatars.
- [Sign-up restrictions](../user/admin_area/settings/sign_up_restrictions.md): block email addresses of specific domains, or whitelist only specific domains.
- [Access restrictions](../user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols): Define which Git access protocols can be used to talk to GitLab (SSH, HTTP, HTTPS).
- [Authentication and Authorization](auth/README.md): Configure external authentication with LDAP, SAML, CAS and additional providers.
  - [Sync LDAP](auth/ldap-ee.md) **(STARTER ONLY)**
  - [Kerberos authentication](../integration/kerberos.md) **(STARTER ONLY)**
  - See also other [authentication](../topics/authentication/index.md#gitlab-administrators) topics (for example, enforcing 2FA).
- [Email users](../tools/email.md): Email GitLab users from within GitLab. **(STARTER ONLY)**
- [User Cohorts](../user/admin_area/user_cohorts.md): Display the monthly cohorts of new users and their activities over time.
- [Audit logs and events](audit_events.md): View the changes made within the GitLab server for:
  - Groups and projects. **(STARTER)**
  - Instances. **(PREMIUM ONLY)**
- [Auditor users](auditor_users.md): Users with read-only access to all projects, groups, and other resources on the GitLab instance. **(PREMIUM ONLY)**
- [Incoming email](incoming_email.md): Configure incoming emails to allow
  users to [reply by email](reply_by_email.md), create [issues by email](../user/project/issues/managing_issues.md#new-issue-via-email) and
  [merge requests by email](../user/project/merge_requests/creating_merge_requests.md#new-merge-request-by-email-core-only), and to enable [Service Desk](../user/project/service_desk.md).
  - [Postfix for incoming email](reply_by_email_postfix_setup.md): Set up a
  basic Postfix mail server with IMAP authentication on Ubuntu for incoming
  emails.
- [Abuse reports](../user/admin_area/abuse_reports.md): View and resolve abuse reports from your users.
- [Credentials Inventory](../user/admin_area/credentials_inventory.md): With Credentials inventory, GitLab administrators can keep track of the credentials used by their users in their GitLab self-managed instance. **(ULTIMATE ONLY)**

## Project settings

- [Issue closing pattern](issue_closing_pattern.md): Customize how to close an issue from commit messages.
- [Gitaly](gitaly/index.md): Configuring Gitaly, GitLab's Git repository storage service.
- [Default labels](../user/admin_area/labels.md): Create labels that will be automatically added to every new project.
- [Restrict the use of public or internal projects](../public_access/public_access.md#restricting-the-use-of-public-or-internal-projects): Restrict the use of visibility levels for users when they create a project or a snippet.
- [Custom project templates](../user/admin_area/custom_project_templates.md): Configure a set of projects to be used as custom templates when creating a new project. **(PREMIUM ONLY)**

## Package Registry administration

- [Container Registry](packages/container_registry.md): Configure Container Registry with GitLab.
- [Package Registry](packages/index.md): Enable GitLab to act as an NPM Registry and a Maven Repository. **(PREMIUM ONLY)**
- [Dependency Proxy](packages/dependency_proxy.md): Configure the Dependency Proxy, a local proxy for frequently used upstream images/packages. **(PREMIUM ONLY)**

### Repository settings

- [Repository checks](repository_checks.md): Periodic Git repository checks.
- [Repository storage paths](repository_storage_paths.md): Manage the paths used to store repositories.
- [Repository storage types](repository_storage_types.md): Information about the different repository storage types.
- [Repository storage rake tasks](raketasks/storage.md): A collection of rake tasks to list and migrate existing projects and attachments associated with it from Legacy storage to Hashed storage.
- [Limit repository size](../user/admin_area/settings/account_and_limit_settings.md): Set a hard limit for your repositories' size. **(STARTER ONLY)**
- [Static objects external storage](static_objects_external_storage.md): Set external storage for static objects in a repository.

## Continuous Integration settings

- [Enable/disable GitLab CI/CD](../ci/enable_or_disable_ci.md#site-wide-admin-setting): Enable or disable GitLab CI/CD for your instance.
- [GitLab CI/CD admin settings](../user/admin_area/settings/continuous_integration.md): Enable or disable Auto DevOps site-wide and define the artifacts' max size and expiration time.
- [External Pipeline Validation](external_pipeline_validation.md): Enable, disable and configure external pipeline validation.
- [Job artifacts](job_artifacts.md): Enable, disable, and configure job artifacts (a set of files and directories which are outputted by a job when it completes successfully).
- [Job logs](job_logs.md): Information about the job logs.
- [Register Shared and specific Runners](../ci/runners/README.md#registering-a-shared-runner): Learn how to register and configure Shared and specific Runners to your own instance.
- [Shared Runners pipelines quota](../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota-starter-only): Limit the usage of pipeline minutes for Shared Runners. **(STARTER ONLY)**
- [Enable/disable Auto DevOps](../topics/autodevops/index.md#enablingdisabling-auto-devops): Enable or disable Auto DevOps for your instance.

## Snippet settings

- [Setting snippet content size limit](snippets/index.md): Set a maximum size limit for snippets' content.

## Git configuration options

- [Custom Git hooks](custom_hooks.md): Custom Git hooks (on the filesystem) for when webhooks aren't enough.
- [Git LFS configuration](lfs/lfs_administration.md): Learn how to configure LFS for GitLab.
- [Housekeeping](housekeeping.md): Keep your Git repositories tidy and fast.
- [Configuring Git Protocol v2](git_protocol.md): Git protocol version 2 support.
- [Manage large files with `git-annex` (Deprecated)](git_annex.md)

## Monitoring GitLab

- [Monitoring GitLab](monitoring/index.md):
  - [Monitoring uptime](../user/admin_area/monitoring/health_check.md): Check the server status using the health check endpoint.
  - [IP whitelist](monitoring/ip_whitelist.md): Monitor endpoints that provide health check information when probed.
  - [Monitoring GitHub imports](monitoring/github_imports.md): GitLab's GitHub Importer displays Prometheus metrics to monitor the health and progress of the importer.

### Performance Monitoring

- [GitLab Performance Monitoring](monitoring/performance/index.md):
  - [Enable Performance Monitoring](monitoring/performance/gitlab_configuration.md): Enable GitLab Performance Monitoring.
  - [GitLab performance monitoring with InfluxDB](monitoring/performance/influxdb_configuration.md): Configure GitLab and InfluxDB for measuring performance metrics.
  - [InfluxDB Schema](monitoring/performance/influxdb_schema.md): Measurements stored in InfluxDB.
  - [GitLab performance monitoring with Prometheus](monitoring/prometheus/index.md): Configure GitLab and Prometheus for measuring performance metrics.
  - [GitLab performance monitoring with Grafana](monitoring/performance/grafana_configuration.md): Configure GitLab to visualize time series metrics through graphs and dashboards.
  - [Request Profiling](monitoring/performance/request_profiling.md): Get a detailed profile on slow requests.
  - [Performance Bar](monitoring/performance/performance_bar.md): Get performance information for the current page.

## Analytics

- [Pseudonymizer](pseudonymizer.md): Export data from GitLab's database to CSV files in a secure way. **(ULTIMATE)**

## Troubleshooting

- [Debugging tips](troubleshooting/debug.md): Tips to debug problems when things go wrong
- [Log system](logs.md): Where to look for logs.
- [Sidekiq Troubleshooting](troubleshooting/sidekiq.md): Debug when Sidekiq appears hung and is not processing jobs.
- [Troubleshooting Elasticsearch](troubleshooting/elasticsearch.md)

### Support Team Docs

The GitLab Support Team has collected a lot of information about troubleshooting GitLab
instances. These documents are normally used by the Support Team itself, or by customers
with direct guidance from a Support Team member. GitLab administrators may find the
information useful for troubleshooting, but if you are experiencing trouble with your
GitLab instance, you should check your [support options](https://about.gitlab.com/support/)
before referring to these documents.

CAUTION: **Warning:**
Using the commands listed in the documentation below could result in data loss or
other damage to a GitLab instance, and should only be used by experienced administrators
who are aware of the risks.

- [Useful diagnostics tools](troubleshooting/diagnostics_tools.md)
- [Useful Linux commands](troubleshooting/linux_cheat_sheet.md)
- [Troubleshooting Kubernetes](troubleshooting/kubernetes_cheat_sheet.md)
- [Troubleshooting PostgreSQL](troubleshooting/postgresql.md)
- [Guide to test environments](troubleshooting/test_environments.md) (for Support Engineers)
- [GitLab Rails console commands](troubleshooting/gitlab_rails_cheat_sheet.md) (for Support Engineers)
- Useful links:
  - [GitLab Developer Docs](../development/README.md)
  - [Repairing and recovering broken Git repositories](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [Testing with OpenSSL](https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html)
  - [Strace zine](https://wizardzines.com/zines/strace/)
