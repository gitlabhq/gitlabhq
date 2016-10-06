# Documentation

## User documentation

- [Account Security](user/account/security.md) Securing your account via two-factor authentication, etc.
- [API](api/README.md) Automate GitLab via a simple and powerful API.
- [CI/CD](ci/README.md) GitLab Continuous Integration (CI) and Continuous Delivery (CD) getting started, `.gitlab-ci.yml` options, and examples.
- [GitLab as OAuth2 authentication service provider](integration/oauth_provider.md). It allows you to login to other applications from GitLab.
- [Container Registry](user/project/container_registry.md) Learn how to use GitLab Container Registry.
- [GitLab Basics](gitlab-basics/README.md) Find step by step how to start working on your commandline and on GitLab.
- [Importing to GitLab](workflow/importing/README.md).
- [Importing and exporting projects between instances](user/project/settings/import_export.md).
- [Markdown](user/markdown.md) GitLab's advanced formatting system.
- [Migrating from SVN](workflow/importing/migrating_from_svn.md) Convert a SVN repository to Git and GitLab.
- [Permissions](user/permissions.md) Learn what each role in a project (external/guest/reporter/developer/master/owner) can do.
- [Profile Settings](profile/README.md)
- [Project Services](project_services/project_services.md) Integrate a project with external services, such as CI and chat.
- [Public access](public_access/public_access.md) Learn how you can allow public and internal access to projects.
- [SSH](ssh/README.md) Setup your ssh keys and deploy keys for secure access to your projects.
- [Webhooks](web_hooks/web_hooks.md) Let GitLab notify you when new code has been pushed to your project.
- [Workflow](workflow/README.md) Using GitLab functionality and importing projects from GitHub and SVN.
- [University](university/README.md) Learn Git and GitLab through videos and courses.

## Administrator documentation

- [Access restrictions](user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols) Define which Git access protocols can be used to talk to GitLab
- [Authentication/Authorization](administration/auth/README.md) Configure
  external authentication with LDAP, SAML, CAS and additional Omniauth providers.
- [Custom Git hooks](administration/custom_hooks.md) Custom Git hooks (on the filesystem) for when webhooks aren't enough.
- [Install](install/README.md) Requirements, directory structures and installation from source.
- [Restart GitLab](administration/restart_gitlab.md) Learn how to restart GitLab and its components.
- [Integration](integration/README.md) How to integrate with systems such as JIRA, Redmine, Twitter.
- [Issue closing pattern](administration/issue_closing_pattern.md) Customize how to close an issue from commit messages.
- [Koding](administration/integration/koding.md) Set up Koding to use with GitLab.
- [Libravatar](customization/libravatar.md) Use Libravatar instead of Gravatar for user avatars.
- [Log system](administration/logs.md) Log system.
- [Environment Variables](administration/environment_variables.md) to configure GitLab.
- [Operations](operations/README.md) Keeping GitLab up and running.
- [Raketasks](raketasks/README.md) Backups, maintenance, automatic webhook setup and the importing of projects.
- [Repository checks](administration/repository_checks.md) Periodic Git repository checks.
- [Repository storages](administration/repository_storages.md) Manage the paths used to store repositories.
- [Security](security/README.md) Learn what you can do to further secure your GitLab instance.
- [System hooks](system_hooks/system_hooks.md) Notifications when users, projects and keys are changed.
- [Update](update/README.md) Update guides to upgrade your installation.
- [Welcome message](customization/welcome_message.md) Add a custom welcome message to the sign-in page.
- [Reply by email](incoming_email/README.md) Allow users to comment on issues and merge requests by replying to notification emails.
- [Migrate GitLab CI to CE/EE](migrate_ci_to_ce/README.md) Follow this guide to migrate your existing GitLab CI data to GitLab CE/EE.
- [Git LFS configuration](workflow/lfs/lfs_administration.md)
- [Housekeeping](administration/housekeeping.md) Keep your Git repository tidy and fast.
- [GitLab Performance Monitoring](monitoring/performance/introduction.md) Configure GitLab and InfluxDB for measuring performance metrics.
- [Monitoring uptime](monitoring/health_check.md) Check the server status using the health check endpoint.
- [Debugging Tips](administration/troubleshooting/debug.md) Tips to debug problems when things go wrong
- [Sidekiq Troubleshooting](administration/troubleshooting/sidekiq.md) Debug when Sidekiq appears hung and is not processing jobs.
- [High Availability](administration/high_availability/README.md) Configure multiple servers for scaling or high availability.
- [Container Registry](administration/container_registry.md) Configure Docker Registry with GitLab.
- [Multiple mountpoints for the repositories storage](administration/repository_storages.md) Define multiple repository storage paths to distribute the storage load.

## Contributor documentation

- [Development](development/README.md) All styleguides and explanations how to contribute.
- [Legal](legal/README.md) Contributor license agreements.
