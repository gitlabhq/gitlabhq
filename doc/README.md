# GitLab Enterprise Edition documentation

## University

[University](university/README.md) contain guides to learn Git and GitLab through courses and videos.

## User documentation

- [Account Security](user/profile/account/two_factor_authentication.md) Securing your account via two-factor authentication, etc.
- [API](api/README.md) Automate GitLab via a simple and powerful API.
- [CI/CD](ci/README.md) GitLab Continuous Integration (CI) and Continuous Delivery (CD) getting started, `.gitlab-ci.yml` options, and examples.
- [GitLab as OAuth2 authentication service provider](integration/oauth_provider.md). It allows you to login to other applications from GitLab.
- [Container Registry](user/project/container_registry.md) Learn how to use GitLab Container Registry.
- [GitLab basics](gitlab-basics/README.md) Find step by step how to start working on your commandline and on GitLab.
- [GitLab Pages](user/project/pages/index.md) Using GitLab Pages.
- [Importing to GitLab](workflow/importing/README.md) Import your projects from GitHub, Bitbucket, GitLab.com, FogBugz and SVN into GitLab.
- [Importing and exporting projects between instances](user/project/settings/import_export.md).
- [Koding](user/project/koding.md) Learn how to use Koding, the online IDE.
- [Markdown](user/markdown.md) GitLab's advanced formatting system.
- [Migrating from SVN](workflow/importing/migrating_from_svn.md) Convert a SVN repository to Git and GitLab.
- [Permissions](user/permissions.md) Learn what each role in a project (external/guest/reporter/developer/master/owner) can do.
- [Profile Settings](profile/README.md)
- [Project Services](user/project/integrations//project_services.md) Integrate a project with external services, such as CI and chat.
- [Public access](public_access/public_access.md) Learn how you can allow public and internal access to projects.
- [Analytics](analytics/README.md)
- [Snippets](user/snippets.md) Snippets allow you to create little bits of code.
- [SSH](ssh/README.md) Setup your ssh keys and deploy keys for secure access to your projects.
- [Webhooks](user/project/integrations/webhooks.md) Let GitLab notify you when new code has been pushed to your project.
- [Workflow](workflow/README.md) Using GitLab functionality and importing projects from GitHub and SVN.
- [Git Attributes](user/project/git_attributes.md) Managing Git attributes using a `.gitattributes` file.
- [Git cheatsheet](https://gitlab.com/gitlab-com/marketing/raw/master/design/print/git-cheatsheet/print-pdf/git-cheatsheet.pdf) Download a PDF describing the most used Git operations.

## Administrator documentation

- [Upload your GitLab License](user/admin_area/license.md) Upload the license you purchased for GitLab Enterprise Edition to unlock its features.
- [Audit Events](administration/audit_events.md) Check how user access changed in projects and groups.
- [Access restrictions](user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols) Define which Git access protocols can be used to talk to GitLab
- [Authentication/Authorization](administration/auth/README.md) Configure
  external authentication with LDAP, SAML, CAS and additional Omniauth providers.
- [Changing the appearance of the login page](customization/branded_login_page.md) Make the login page branded for your GitLab instance.
- [Custom git hooks](administration/custom_hooks.md) Custom git hooks (on the filesystem) for when webhooks aren't enough.
- [Email](tools/email.md) Email GitLab users from GitLab
- [Push Rules](push_rules/push_rules.md) Advanced push rules for your project.
- [Help message](customization/help_message.md) Set information about administrators of your GitLab instance.
- [Install](install/README.md) Requirements, directory structures and installation from source.
- [Integration](integration/README.md) How to integrate with systems such as JIRA, Redmine, LDAP and Twitter.
- [Restart GitLab](administration/restart_gitlab.md) Learn how to restart GitLab and its components.
- [Issue closing pattern](administration/issue_closing_pattern.md) Customize how to close an issue from commit messages.
- [Koding](administration/integration/koding.md) Set up Koding to use with GitLab.
- [Web terminals](administration/integration/terminal.md) Provide terminal access to environments from within GitLab.
- [Libravatar](customization/libravatar.md) Use Libravatar instead of Gravatar for user avatars.
- [Log system](administration/logs.md) Log system.
- [Environment Variables](administration/environment_variables.md) to configure GitLab.
- [Operations](administration/operations.md) Keeping GitLab up and running.
- [Raketasks](raketasks/README.md) Backups, maintenance, automatic webhook setup and the importing of projects.
- [Repository checks](administration/repository_checks.md) Periodic Git repository checks.
- [Repository storage paths](administration/repository_storage_paths.md) Manage the paths used to store repositories.
- [Security](security/README.md) Learn what you can do to further secure your GitLab instance.
- [System hooks](system_hooks/system_hooks.md) Notifications when users, projects and keys are changed.
- [Update](update/README.md) Update guides to upgrade your installation.
- [Welcome message](customization/welcome_message.md) Add a custom welcome message to the sign-in page.
- [Header logo](customization/branded_page_and_email_header.md) Change the logo on the overall page and email header.
- [Reply by email](administration/reply_by_email.md) Allow users to comment on issues and merge requests by replying to notification emails.
- [Migrate GitLab CI to CE/EE](migrate_ci_to_ce/README.md) Follow this guide to migrate your existing GitLab CI data to GitLab CE/EE.
- [Downgrade back to CE](downgrade_ee_to_ce/README.md) Follow this guide if you need to downgrade from EE to CE.
- [git-annex configuration](workflow/git_annex.md#configuration)
- [Git LFS configuration](workflow/lfs/lfs_administration.md)
- [Housekeeping](administration/housekeeping.md) Keep your Git repository tidy and fast.
- [GitLab Pages configuration](administration/pages/index.md) Configure GitLab Pages.
- [Elasticsearch](integration/elasticsearch.md) Enable Elasticsearch.
- [GitLab GEO](gitlab-geo/README.md) Configure GitLab GEO, a secondary read-only GitLab instance.
- [GitLab performance monitoring with InfluxDB](administration/monitoring/performance/introduction.md) Configure GitLab and InfluxDB for measuring performance metrics.
- [GitLab performance monitoring with Prometheus](administration/monitoring/prometheus/index.md) Configure GitLab and Prometheus for measuring performance metrics.
- [Request Profiling](administration/monitoring/performance/request_profiling.md) Get a detailed profile on slow requests.
- [Monitoring uptime](user/admin_area/monitoring/health_check.md) Check the server status using the health check endpoint.
- [Debugging Tips](administration/troubleshooting/debug.md) Tips to debug problems when things go wrong
- [Sidekiq Troubleshooting](administration/troubleshooting/sidekiq.md) Debug when Sidekiq appears hung and is not processing jobs.
- [High Availability](administration/high_availability/README.md) Configure multiple servers for scaling or high availability.
- [Container Registry](administration/container_registry.md) Configure Docker Registry with GitLab.
- [Repository restrictions](user/admin_area/settings/account_and_limit_settings.md#repository-size-limit) Define size restrictions for your repositories to limit the space they occupy in your storage device. Includes LFS objects.
- [Auditor users](administration/auditor_users.md) Create auditor users, with read-only access to the entire system.

## Contributor documentation

- [Development](development/README.md) All styleguides and explanations how to contribute.
- [Legal](legal/README.md) Contributor license agreements.
