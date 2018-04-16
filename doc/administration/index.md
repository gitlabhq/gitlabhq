# Administrator documentation

Learn how to administer your GitLab instance (Community Edition and
Enterprise Edition).
Regular users don't have access to GitLab administration tools and settings.

GitLab has two product distributions: the open source
[GitLab Community Edition (CE)](https://gitlab.com/gitlab-org/gitlab-ce),
and the open core [GitLab Enterprise Edition (EE)](https://gitlab.com/gitlab-org/gitlab-ee),
available through [different subscriptions](https://about.gitlab.com/products/).

You can [install GitLab CE or GitLab EE](https://about.gitlab.com/installation/ce-or-ee/),
but the features you'll have access to depend on the subscription you choose
(Core, Starter, Premium, or Ultimate). GitLab Community Edition installations
only have access to Core features.

GitLab.com is administered by GitLab, Inc., therefore, only GitLab team members have
access to its admin configurations. If you're a GitLab.com user, please check the
[user documentation](../user/index.html).

## Installing and maintaining GitLab

Learn how to install, configure, update, and maintain your GitLab instance.

### Installing GitLab

- [Install](../install/README.md): Requirements, directory structures, and installation methods.
  - [Database load balancing](database_load_balancing.md): Distribute database queries among multiple database servers. **[STARTER ONLY]**
  - [Omnibus support for external MySQL DB](https://docs.gitlab.com/omnibus/settings/database.html#using-a-mysql-database-management-server-enterprise-edition-only): Omnibus package supports configuring an external MySQL database. **[STARTER ONLY]**
  - [Omnibus support for log forwarding](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only) **[STARTER ONLY]**
- [High Availability](high_availability/README.md): Configure multiple servers for scaling or high availability.
  - [High Availability on AWS](../university/high-availability/aws/README.md): Set up GitLab HA on Amazon AWS.
- [Geo](geo/replication/index.md): Replicate your GitLab instance to other geographical locations as a read-only fully operational version. **[PREMIUM ONLY]**
- [Disaster Recovery](geo/disaster_recovery/index.md): Quickly fail-over to a different site with minimal effort in a disaster situation. **[PREMIUM ONLY]**
- [Pivotal Tile](../install/pivotal/index.md): Deploy GitLab as a pre-configured appliance using Ops Manager (BOSH) for Pivotal Cloud Foundry. **[PREMIUM ONLY]**

### Configuring GitLab

- [Adjust your instance's timezone](../workflow/timezone.md): Customize the default time zone of GitLab.
- [System hooks](../system_hooks/system_hooks.md): Notifications when users, projects and keys are changed.
- [Security](../security/README.md): Learn what you can do to further secure your GitLab instance.
- [Usage statistics, version check, and usage ping](../user/admin_area/settings/usage_statistics.md): Enable or disable information about your instance to be sent to GitLab, Inc.
- [Polling](polling.md): Configure how often the GitLab UI polls for updates.
- [GitLab Pages configuration](pages/index.md): Enable and configure GitLab Pages.
- [GitLab Pages configuration for GitLab source installations](pages/source.md): Enable and configure GitLab Pages on
- [Uploads configuration](uploads.md): Configure GitLab uploads storage.
[source installations](../install/installation.md#installation-from-source).
- [Environment variables](environment_variables.md): Supported environment variables that can be used to override their defaults values in order to configure GitLab.
- [Elasticsearch](../integration/elasticsearch.md): Enable Elasticsearch to empower GitLab's Advanced Global Search. Useful when you deal with a huge amount of data. **[STARTER ONLY]**
- [External Classification Policy Authorization](../user/admin_area/settings/external_authorization.md) **[PREMIUM ONLY]**

#### Customizing GitLab's appearance

- [Header logo](../customization/branded_page_and_email_header.md): Change the logo on all pages and email headers.
- [Branded login page](../customization/branded_login_page.md): Customize the login page with your own logo, title, and description.
- [Welcome message](../customization/welcome_message.md): Add a custom welcome message to the sign-in page.
- ["New Project" page](../customization/new_project_page.md): Customize the text to be displayed on the page that opens whenever your users create a new project.

### Maintaining GitLab

- [Raketasks](../raketasks/README.md): Perform various tasks for maintenance, backups, automatic webhooks setup, etc.
  - [Backup and restore](../raketasks/backup_restore.md): Backup and restore your GitLab instance.
- [Operations](operations/index.md): Keeping GitLab up and running (clean up Redis sessions, moving repositories, Sidekiq Job throttling, Sidekiq MemoryKiller, Unicorn).
- [Restart GitLab](restart_gitlab.md): Learn how to restart GitLab and its components.

#### Updating GitLab

- [GitLab versions and maintenance policy](../policy/maintenance.md): Understand GitLab versions and releases (Major, Minor, Patch, Security), as well as update recommendations.
- [Update GitLab](../update/README.md): Update guides to upgrade your installation to a new version.
- [Downtimeless updates](../update/README.md#upgrading-without-downtime): Upgrade to a newer major, minor, or patch version of GitLab without taking your GitLab instance offline.
- [Migrate your GitLab CI/CD data to another version of GitLab](../migrate_ci_to_ce/README.md): If you have an old GitLab installation (older than 8.0), follow this guide to migrate your existing GitLab CI/CD data to another version of GitLab.

### Upgrading or downgrading GitLab

- [Upgrade from GitLab CE to GitLab EE](../update/README.md#upgrading-between-editions): learn how to upgrade GitLab Community Edition to GitLab Enterprise Editions.
- [Downgrade from GitLab EE to GitLab CE](../downgrade_ee_to_ce/README.md): Learn how to downgrade GitLab Enterprise Editions to Community Edition.

### GitLab platform integrations

- [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/): Integrate with [Mattermost](https://about.mattermost.com/), an open source, private cloud workplace for web messaging.
- [PlantUML](integration/plantuml.md): Create simple diagrams in AsciiDoc and Markdown documents
created in snippets, wikis, and repos.
- [Web terminals](integration/terminal.md): Provide terminal access to your applications deployed to Kubernetes from within GitLab's CI/CD [environments](../ci/environments.md#web-terminals).

## User settings and permissions

- [Libravatar](../customization/libravatar.md): Use Libravatar instead of Gravatar for user avatars.
- [Sign-up restrictions](../user/admin_area/settings/sign_up_restrictions.md): block email addresses of specific domains, or whitelist only specific domains.
- [Access restrictions](../user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols): Define which Git access protocols can be used to talk to GitLab (SSH, HTTP, HTTPS).
- [Authentication/Authorization](../topics/authentication/index.md#gitlab-administrators): Enforce 2FA, configure external authentication with LDAP, SAML, CAS and additional Omniauth providers.
  - [Sync LDAP](auth/ldap-ee.md) **[STARTER ONLY]**
  - [Kerberos authentication](../integration/kerberos.md) **[STARTER ONLY]**
- [Email users](../tools/email.md): Email GitLab users from within GitLab. **[STARTER ONLY]**
- [User Cohorts](../user/admin_area/user_cohorts.md): Display the monthly cohorts of new users and their activities over time.
- [Audit logs and events](audit_events.md): View the changes made within the GitLab server. **[STARTER ONLY]**
- [Auditor users](auditor_users.md): Users with read-only access to all projects, groups, and other resources on the GitLab instance. **[PREMIUM ONLY]**
- [Incoming email](incoming_email.md): Configure incoming emails to allow
  users to [reply by email], create [issues by email] and
  [merge requests by email], and to enable [Service Desk].
  - [Postfix for incoming email](reply_by_email_postfix_setup.md): Set up a
  basic Postfix mail server with IMAP authentication on Ubuntu for incoming
  emails.
server with IMAP authentication on Ubuntu, to be used with Reply by email.
- [User Cohorts](../user/admin_area/user_cohorts.md): Display the monthly cohorts of new users and their activities over time.

[reply by email]: reply_by_email.md
[issues by email]: ../user/project/issues/create_new_issue.md#new-issue-via-email
[merge requests by email]: ../user/project/merge_requests/index.md#create-new-merge-requests-by-email
[Service Desk]: ../user/project/service_desk.md

## Project settings

- [Container Registry](container_registry.md): Configure Container Registry with GitLab.
- [Issue closing pattern](issue_closing_pattern.md): Customize how to close an issue from commit messages.
- [Gitaly](gitaly/index.md): Configuring Gitaly, GitLab's Git repository storage service.
- [Default labels](../user/admin_area/labels.html): Create labels that will be automatically added to every new project.
- [Restrict the use of public or internal projects](../public_access/public_access.md#restricting-the-use-of-public-or-internal-projects): Restrict the use of visibility levels for users when they create a project or a snippet.

### Repository settings

- [Repository checks](repository_checks.md): Periodic Git repository checks.
- [Repository storage paths](repository_storage_paths.md): Manage the paths used to store repositories.
- [Repository storage rake tasks](raketasks/storage.md): A collection of rake tasks to list and migrate existing projects and attachments associated with it from Legacy storage to Hashed storage.
- [Limit repository size](../user/admin_area/settings/account_and_limit_settings.md): Set a hard limit for your repositories' size. **[STARTER ONLY]**

## Continuous Integration settings

- [Enable/disable GitLab CI/CD](../ci/enable_or_disable_ci.md#site-wide-admin-setting): Enable or disable GitLab CI/CD for your instance.
- [GitLab CI/CD admin settings](../user/admin_area/settings/continuous_integration.md): Define max artifacts size and expiration time.
- [Job artifacts](job_artifacts.md): Enable, disable, and configure job artifacts (a set of files and directories which are outputted by a job when it completes successfully).
- [Job traces](job_traces.md): Information about the job traces (logs).
- [Artifacts size and expiration](../user/admin_area/settings/continuous_integration.md#maximum-artifacts-size): Define maximum artifacts limits and expiration date.
- [Register Shared and specific Runners](../ci/runners/README.md#registering-a-shared-runner): Learn how to register and configure Shared and specific Runners to your own instance.
- [Shared Runners pipelines quota](../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota): Limit the usage of pipeline minutes for Shared Runners.
- [Enable/disable Auto DevOps](../topics/autodevops/index.md#enabling-auto-devops): Enable or disable Auto DevOps for your instance.

## Git configuration options

- [Custom Git hooks](custom_hooks.md): Custom Git hooks (on the filesystem) for when webhooks aren't enough.
- [Git LFS configuration](../workflow/lfs/lfs_administration.md): Learn how to configure LFS for GitLab.
- [Housekeeping](housekeeping.md): Keep your Git repositories tidy and fast.

## Monitoring GitLab

- [Monitoring GitLab](monitoring/index.md):
  - [Monitoring uptime](../user/admin_area/monitoring/health_check.md): Check the server status using the health check endpoint.
    - [IP whitelist](monitoring/ip_whitelist.md): Monitor endpoints that provide health check information when probed.
    - [Monitoring GitHub imports](monitoring/github_imports.md): GitLab's GitHub Importer displays Prometheus metrics to monitor the health and progress of the importer.
- [Conversational Development (ConvDev) Index](../user/admin_area/monitoring/convdev.md): Provides an overview of your entire instance's feature usage.

### Performance Monitoring

- [GitLab Performance Monitoring](monitoring/performance/index.md):
  - [Enable Performance Monitoring](monitoring/performance/gitlab_configuration.md): Enable GitLab Performance Monitoring.
  - [GitLab performance monitoring with InfluxDB](monitoring/performance/influxdb_configuration.md): Configure GitLab and InfluxDB for measuring performance metrics.
    - [InfluxDB Schema](monitoring/performance/influxdb_schema.md): Measurements stored in InfluxDB.
  - [GitLab performance monitoring with Prometheus](monitoring/prometheus/index.md): Configure GitLab and Prometheus for measuring performance metrics.
  - [GitLab performance monitoring with Grafana](monitoring/performance/grafana_configuration.md): Configure GitLab to visualize time series metrics through graphs and dashboards.
  - [Request Profiling](monitoring/performance/request_profiling.md): Get a detailed profile on slow requests.
  - [Performance Bar](monitoring/performance/performance_bar.md): Get performance information for the current page.

## Troubleshooting

- [Debugging tips](troubleshooting/debug.md): Tips to debug problems when things go wrong
- [Log system](logs.md): Where to look for logs.
- [Sidekiq Troubleshooting](troubleshooting/sidekiq.md): Debug when Sidekiq appears hung and is not processing jobs.
