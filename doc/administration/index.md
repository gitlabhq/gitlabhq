---
stage: Enablement
group: Distribution
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
description: 'Learn how to install, configure, update, and maintain your GitLab instance.'
---

# Administrator documentation **(FREE SELF)**

If you use GitLab.com, only GitLab team members have access to administration tools and settings.
If you use a self-managed GitLab instance, learn how to administer it.

Only administrator users can access GitLab administration tools and settings.

## Available distributions

GitLab has two product distributions available through [different subscriptions](https://about.gitlab.com/pricing/):

- The open source [GitLab Community Edition (CE)](https://gitlab.com/gitlab-org/gitlab-foss).
- The open core [GitLab Enterprise Edition (EE)](https://gitlab.com/gitlab-org/gitlab).

You can [install either GitLab CE or GitLab EE](https://about.gitlab.com/install/ce-or-ee/).
However, the features you have access to depend on your chosen subscription.

GitLab Community Edition installations have access only to Free features.

## Installing and maintaining GitLab

Learn how to install, configure, update, and maintain your GitLab instance.

### Installing GitLab

- [Install](../install/index.md): Requirements, directory structures, and installation methods.
  - [Database load balancing](database_load_balancing.md): Distribute database queries among multiple database servers.
  - [Omnibus support for log forwarding](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only).
- [Reference architectures](reference_architectures/index.md): Add additional resources to support more users.
  - [Installing GitLab on Amazon Web Services (AWS)](../install/aws/index.md): Set up GitLab on Amazon AWS.
- [Geo](geo/index.md): Replicate your GitLab instance to other geographic locations as a read-only fully operational version.
- [Disaster Recovery](geo/disaster_recovery/index.md): Quickly fail-over to a different site with minimal effort in a disaster situation.
- [Add License](../user/admin_area/license.md): Upload a license at install time to unlock features that are in paid tiers of GitLab.

### Configuring GitLab

- [Adjust your instance's timezone](timezone.md): Customize the default time zone of GitLab.
- [System hooks](../system_hooks/system_hooks.md): Notifications when users, projects and keys are changed.
- [Security](../security/index.md): Learn what you can do to further secure your GitLab instance.
- [Usage statistics, version check, and usage ping](../user/admin_area/settings/usage_statistics.md): Enable or disable information about your instance to be sent to GitLab, Inc.
- [Global user settings](user_settings.md): Configure instance-wide user permissions.
- [Polling](polling.md): Configure how often the GitLab UI polls for updates.
- [GitLab Pages configuration](pages/index.md): Enable and configure GitLab Pages.
- [GitLab Pages configuration for GitLab source installations](pages/source.md):
  Enable and configure GitLab Pages on [source installations](../install/installation.md#installation-from-source).
- [Uploads administration](uploads.md): Configure GitLab uploads storage.
- [Environment variables](environment_variables.md): Supported environment
  variables that can be used to override their default values to configure
  GitLab.
- [File hooks](file_hooks.md): With custom file hooks, GitLab administrators can
  introduce custom integrations without modifying GitLab source code.
- [Enforcing Terms of Service](../user/admin_area/settings/terms.md)
- [Third party offers](../user/admin_area/settings/third_party_offers.md)
- [Compliance](compliance.md): A collection of features from across the
  application that you may configure to help ensure that your GitLab instance
  and DevOps workflow meet compliance standards.
- [Diff limits](../user/admin_area/diff_limits.md): Configure the diff rendering
  size limits of branch comparison pages.
- [Merge request diffs storage](merge_request_diffs.md): Configure merge
  requests diffs external storage.
- [Broadcast Messages](../user/admin_area/broadcast_messages.md): Send messages
  to GitLab users through the UI.
- [Elasticsearch](../integration/elasticsearch.md): Enable Elasticsearch to
  empower Advanced Search. Use when you deal with a huge amount of data.
- [External Classification Policy Authorization](../user/admin_area/settings/external_authorization.md)
- [Upload a license](../user/admin_area/license.md): Upload a license to unlock
  features that are in paid tiers of GitLab.
- [Admin Area](../user/admin_area/index.md): for self-managed instance-wide
  configuration and maintenance.
- [S/MIME Signing](smime_signing_email.md): how to sign all outgoing notification
  emails with S/MIME.
- [Enabling and disabling features flags](feature_flags.md): how to enable and
  disable GitLab features deployed behind feature flags.
- [Application settings cache expiry interval](application_settings_cache.md)

#### Customizing GitLab appearance

- [Header logo](../user/admin_area/appearance.md#navigation-bar): Change the logo on all pages and email headers.
- [Favicon](../user/admin_area/appearance.md#favicon): Change the default favicon to your own logo.
- [Branded login page](../user/admin_area/appearance.md#sign-in--sign-up-pages): Customize the login page with your own logo, title, and description.
- ["New Project" page](../user/admin_area/appearance.md#new-project-pages): Customize the text to be displayed on the page that opens whenever your users create a new project.
- [Additional custom email text](../user/admin_area/settings/email.md#custom-additional-text): Add additional custom text to emails sent from GitLab.

### Maintaining GitLab

- [Rake tasks](../raketasks/index.md): Perform various tasks for maintenance, backups, automatic webhooks setup, and more.
  - [Backup and restore](../raketasks/backup_restore.md): Backup and restore your GitLab instance.
- [Operations](operations/index.md): Keeping GitLab up and running (clean up Redis sessions, moving repositories, Sidekiq MemoryKiller, Puma).
- [Restart GitLab](restart_gitlab.md): Learn how to restart GitLab and its components.
- [Invalidate Markdown cache](invalidate_markdown_cache.md): Invalidate any cached Markdown.
- [Instance review](instance_review.md): Request a free review of your GitLab instance.

#### Updating GitLab

- [GitLab versions and maintenance policy](../policy/maintenance.md): Understand GitLab versions and releases (Major, Minor, Patch, Security), as well as update recommendations.
- [GitLab in maintenance mode](maintenance_mode/index.md): Put GitLab in maintenance mode.
- [Update GitLab](../update/index.md): Update guides to upgrade your installation to a new version.
- [Upgrading without downtime](../update/index.md#upgrading-without-downtime): Upgrade to a newer major, minor, or patch version of GitLab without taking your GitLab instance offline.

### Upgrading or downgrading GitLab

- [Upgrade from GitLab CE to GitLab EE](../update/index.md#upgrading-between-editions): Learn how to upgrade GitLab Community Edition to GitLab Enterprise Editions.
- [Downgrade from GitLab EE to GitLab CE](../downgrade_ee_to_ce/index.md): Learn how to downgrade GitLab Enterprise Editions to Community Edition.

### GitLab platform integrations

- [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/): Integrate with [Mattermost](https://mattermost.com), an open source, private cloud workplace for web messaging.
- [PlantUML](integration/plantuml.md): Create diagrams in AsciiDoc and Markdown documents
  created in snippets, wikis, and repositories.
- [Web terminals](integration/terminal.md): Provide terminal access to your applications deployed to Kubernetes from GitLab CI/CD [environments](../ci/environments/index.md#web-terminals).

## User settings and permissions

- [Creating users](../user/profile/account/create_accounts.md): Create users manually or through authentication integrations.
- [Libravatar](libravatar.md): Use Libravatar instead of Gravatar for user avatars.
- [Sign-up restrictions](../user/admin_area/settings/sign_up_restrictions.md): block email addresses of specific domains, or whitelist only specific domains.
- [Access restrictions](../user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols): Define which Git access protocols can be used to talk to GitLab (SSH, HTTP, HTTPS).
- [Authentication and Authorization](auth/index.md): Configure external authentication with LDAP, SAML, CAS, and additional providers.
  - [Sync LDAP](auth/ldap/index.md)
  - [Kerberos authentication](../integration/kerberos.md)
  - See also other [authentication](../topics/authentication/index.md#gitlab-administrators) topics (for example, enforcing 2FA).
- [Email users](../tools/email.md): Email GitLab users from GitLab.
- [User Cohorts](../user/admin_area/user_cohorts.md): Display the monthly cohorts of new users and their activities over time.
- [Audit events](audit_events.md): View the changes made on the GitLab server for:
  - Groups and projects.
  - Instances.
- [Auditor users](auditor_users.md): Users with read-only access to all projects, groups, and other resources on the GitLab instance.
- [Incoming email](incoming_email.md): Configure incoming emails to allow
  users to [reply by email](reply_by_email.md), create [issues by email](../user/project/issues/managing_issues.md#new-issue-via-email) and
  [merge requests by email](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email), and to enable [Service Desk](../user/project/service_desk.md).
  - [Postfix for incoming email](reply_by_email_postfix_setup.md): Set up a
  basic Postfix mail server with IMAP authentication on Ubuntu for incoming
  emails.
- [Abuse reports](../user/admin_area/review_abuse_reports.md): View and resolve abuse reports from your users.
- [Credentials Inventory](../user/admin_area/credentials_inventory.md): With Credentials inventory, GitLab administrators can keep track of the credentials used by their users in their GitLab self-managed instance.

## Project settings

- [Issue closing pattern](issue_closing_pattern.md): Customize how to close an issue from commit messages.
- [Gitaly](gitaly/index.md): Configuring Gitaly, the Git repository storage service for GitLab.
- [Default labels](../user/admin_area/labels.md): Create labels that are automatically added to every new project.
- [Restrict the use of public or internal projects](../public_access/public_access.md#restricting-the-use-of-public-or-internal-projects): Restrict the use of visibility levels for users when they create a project or a snippet.
- [Custom project templates](../user/admin_area/custom_project_templates.md): Configure a set of projects to be used as custom templates when creating a new project.

## Package Registry administration

- [Container Registry](packages/container_registry.md): Configure GitLab to act as a registry for containers.
- [Package Registry](packages/index.md): Enable GitLab to act as a registry for packages.
- [Dependency Proxy](packages/dependency_proxy.md): Configure the Dependency Proxy, a local proxy for frequently used upstream images/packages.

### Repository settings

- [Repository checks](repository_checks.md): Check your repository for data corruption.
- [Repository storage paths](repository_storage_paths.md): Manage the paths used to store repositories.
- [Repository storage types](repository_storage_types.md): Information about the different repository storage types.
- [Repository storage Rake tasks](raketasks/storage.md): A collection of Rake tasks to list and migrate existing projects and attachments associated with it from Legacy storage to Hashed storage.
- [Limit repository size](../user/admin_area/settings/account_and_limit_settings.md): Set a hard limit for your repositories' size.
- [Static objects external storage](static_objects_external_storage.md): Set external storage for static objects in a repository.

## Continuous Integration settings

- [Enable/disable GitLab CI/CD](../ci/enable_or_disable_ci.md#site-wide-admin-setting): Enable or disable GitLab CI/CD for your instance.
- [GitLab CI/CD administration settings](../user/admin_area/settings/continuous_integration.md): Enable or disable Auto DevOps site-wide and define the artifacts' max size and expiration time.
- [External Pipeline Validation](external_pipeline_validation.md): Enable, disable, and configure external pipeline validation.
- [Job artifacts](job_artifacts.md): Enable, disable, and configure job artifacts (a set of files and directories which are outputted by a job when it completes successfully).
- [Job logs](job_logs.md): Information about the job logs.
- [Register runners](../ci/runners/runners_scope.md): Learn how to register and configure runners.
- [Shared runners pipelines quota](../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota): Limit the usage of pipeline minutes for shared runners.
- [Enable/disable Auto DevOps](../topics/autodevops/index.md#enable-or-disable-auto-devops): Enable or disable Auto DevOps for your instance.

## Snippet settings

- [Setting snippet content size limit](snippets/index.md): Set a maximum content size limit for snippets.

## Wiki settings

- [Setting wiki page content size limit](wikis/index.md): Set a maximum content size limit for wiki pages.

## Git configuration options

- [Server hooks](server_hooks.md): Server hooks (on the file system) for when webhooks aren't enough.
- [Git LFS configuration](lfs/index.md): Learn how to configure LFS for GitLab.
- [Housekeeping](housekeeping.md): Keep your Git repositories tidy and fast.
- [Configuring Git Protocol v2](git_protocol.md): Git protocol version 2 support.

## Monitoring GitLab

- [Monitoring GitLab](monitoring/index.md):
  - [Monitoring uptime](../user/admin_area/monitoring/health_check.md): Check the server status using the health check endpoint.
  - [IP whitelist](monitoring/ip_whitelist.md): Monitor endpoints that provide health check information when probed.
  - [Monitoring GitHub imports](monitoring/github_imports.md): The GitLab GitHub Importer displays Prometheus metrics to monitor the health and progress of the importer.

### Performance Monitoring

- [GitLab Performance Monitoring](monitoring/performance/index.md):
  - [Enable Performance Monitoring](monitoring/performance/gitlab_configuration.md): Enable GitLab Performance Monitoring.
  - [GitLab performance monitoring with Prometheus](monitoring/prometheus/index.md): Configure GitLab and Prometheus for measuring performance metrics.
  - [GitLab performance monitoring with Grafana](monitoring/performance/grafana_configuration.md): Configure GitLab to visualize time series metrics through graphs and dashboards.
  - [Request Profiling](monitoring/performance/request_profiling.md): Get a detailed profile on slow requests.
  - [Performance Bar](monitoring/performance/performance_bar.md): Get performance information for the current page.

## Analytics

- [Pseudonymizer](pseudonymizer.md): Export data from a GitLab database to CSV files in a secure way.

## Troubleshooting

- [Debugging tips](troubleshooting/debug.md): Tips to debug problems when things go wrong.
- [Log system](logs.md): Where to look for logs.
- [Sidekiq Troubleshooting](troubleshooting/sidekiq.md): Debug when Sidekiq appears hung and is not processing jobs.
- [Troubleshooting Elasticsearch](troubleshooting/elasticsearch.md)
- [Navigating GitLab via Rails console](troubleshooting/navigating_gitlab_via_rails_console.md)
- [GitLab application limits](instance_limits.md)

### Support Team Docs

The GitLab Support Team has collected a lot of information about troubleshooting GitLab.
The following documents are used by the Support Team or by customers
with direct guidance from a Support Team member. GitLab administrators may find the
information useful for troubleshooting. However, if you are experiencing trouble with your
GitLab instance, you should check your [support options](https://about.gitlab.com/support/)
before referring to these documents.

WARNING:
The commands in the following documentation might result in data loss or
other damage to a GitLab instance. They should be used only by experienced administrators
who are aware of the risks.

- [Diagnostics tools](troubleshooting/diagnostics_tools.md)
- [Linux commands](troubleshooting/linux_cheat_sheet.md)
- [Troubleshooting Kubernetes](troubleshooting/kubernetes_cheat_sheet.md)
- [Troubleshooting PostgreSQL](troubleshooting/postgresql.md)
- [Guide to test environments](troubleshooting/test_environments.md) (for Support Engineers)
- [GitLab Rails console commands](troubleshooting/gitlab_rails_cheat_sheet.md) (for Support Engineers)
- [Troubleshooting SSL](troubleshooting/ssl.md)
- Related links:
  - [GitLab Developer Documentation](../development/index.md)
  - [Repairing and recovering broken Git repositories](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [Testing with OpenSSL](https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html)
  - [`strace` zine](https://wizardzines.com/zines/strace/)
- GitLab.com-specific resources:
  - [Group SAML/SCIM setup](troubleshooting/group_saml_scim.md)
