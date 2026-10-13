---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Set up Secrets Manager locally
---

This page walks you through setting up Secrets Manager in the GDK, so you can develop and test features locally.
For an overview of how the feature is built, see [Secrets Manager development guidelines](_index.md).

This setup is for backend work.
If you only work on the frontend, you can run the frontend specs against a plain GDK without OpenBao.
For details, see [Secrets Manager frontend development](frontend.md).

The Secrets Manager UI is being redesigned, so this page uses the Rails console rather than UI steps.
The console services are stable, and they also show you the errors the UI hides.
For the in-progress design, see `gitlab-org/gitlab#605033`, which is confidential and needs GitLab team member access.

## Prerequisites

- A working [GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/).
- GitLab Enterprise Edition with a Premium or Ultimate license. Secrets Manager needs the `native_secrets_management` licensed feature.
- A GDK that serves HTTP at your instance URL, for example `http://gdk.test:3000`. OpenBao validates GitLab JWTs by fetching the OIDC discovery document from that URL, so provisioning fails if GitLab is not serving requests.

## Step 1: Enable OpenBao in the GDK

```shell
gdk config set openbao.enabled true
gdk reconfigure
gdk start openbao
```

GDK builds OpenBao from an internal build that carries GitLab patches, not the upstream release.
The binary lands at `<gdk-root>/openbao/bin/bao`.

To use the CLI, add this to your shell profile:

```shell
export BAO_ADDR='http://gdk.test:8200'
export PATH="<gdk-root>/openbao/bin:$PATH"
```

For the full OpenBao reference, including audit log streaming and admin access, see [OpenBao in the GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/openbao/).

## Step 2: Enroll the instance

Enrollment is the step that most new developers miss.

The GDK behaves as GitLab Self-Managed, so Secrets Manager availability depends on instance enrollment.
The `secrets_manager_instance_enrolled` application setting defaults to `false`.
Secrets Manager stays unavailable even with OpenBao running.

The seed Rake task in Step 3 enrolls for you, so this step matters when you provision a project manually instead.

Enroll from the Rails console:

```ruby
user = User.find_by_username('root')
SecretsManagement::InstanceEnrollmentService.new(current_user: user).enroll
```

If your GDK simulates GitLab.com, enroll the top-level group instead:

```ruby
group = Group.find_by_full_path('your-root-group')
SecretsManagement::NamespaceEnrollmentService.new(group, current_user: user).enroll
```

Both services are safe to run more than once, and both reject the wrong deployment type.
Namespace enrollment works only on GitLab.com, and instance enrollment works only on GitLab Self-Managed.

## Step 3: Seed a working environment

The fastest way to get a working environment is the seed Rake task.
It creates subgroups and projects under a root namespace, provisions the group and project secrets managers, and adds sample secrets.
It also enrolls the instance for you.

```shell
bundle exec rake "gitlab:secrets_management:seed[ROOT_NAMESPACE_ID]"
```

Keep the following in mind:

- The task only runs in the development environment.
- Replace `ROOT_NAMESPACE_ID` with the ID of an existing top-level group.
- The task uses the `root` user, or the first admin if `root` does not exist, and adds that user as an owner of the group.
- Provisioning runs synchronously, so you do not need to wait for Sidekiq.
- Enrollment follows your GDK mode. The task enrolls the namespace when the GDK simulates GitLab.com, and enrolls the instance otherwise.

The task creates this hierarchy under the root namespace:

- `subgroup-a`, holding `project-a1` and `project-a2`, and a `subgroup-a1` holding `project-a1a`.
- `subgroup-b`, holding `project-b1`, and a `subgroup-b1` holding `project-b1x`.
- `project-top1`, directly under the root namespace.

## Step 4: Verify your setup

From the Rails console, confirm that both availability gates pass for a seeded project:

```ruby
project = Project.find_by_full_path('your-root-group/subgroup-a/project-a1')

SecretsManagement::Availability.for_project?(project) # => true
project.secrets_manager.status                        # => "active"
```

If `for_project?` returns `false`, check the gates one at a time:

```ruby
project.licensed_feature_available?(:native_secrets_management) # license
Gitlab::CurrentSettings.secrets_manager_instance_enrolled        # enrollment
```

Then list the seeded secrets:

```ruby
user = User.find_by_username('root')
result = SecretsManagement::ProjectSecrets::ListService.new(project, user).execute
result.payload[:secrets].map(&:name)
```

## Provision manually from the Rails console

Use this when you want to provision a specific project instead of running the seeder.

```ruby
project = Project.find_by_full_path('your-group/your-project')
user = User.find_by_username('root')
project.add_owner(user) unless project.member?(user)

result = SecretsManagement::ProjectSecretsManagers::InitializeService.new(project, user).execute
secrets_manager = result.payload[:project_secrets_manager]

# Run provisioning now instead of waiting for the background worker.
SecretsManagement::ProjectSecretsManagers::ProvisionService.new(secrets_manager, user).execute

secrets_manager.reload.status # => "active"
```

Create a secret:

```ruby
result = SecretsManagement::ProjectSecrets::CreateService.new(project, user).execute(
  name: 'MY_SECRET',
  value: 'super-secret-value',
  description: 'Test secret for local development',
  environment: '*',
  branch: '*'
)

result.success? # => true
```

Groups use the same pattern with the `GroupSecretsManagers` and `GroupSecrets` service namespaces.
Group secrets take a `protected` parameter instead of `branch`.

Standalone `rails runner` scripts need a correlation ID, because the OpenBao authorization program reads the `correlation_id` claim.
Wrap your calls:

```ruby
Labkit::Correlation::CorrelationId.use_id('local-testing') do
  # your Secrets Manager calls
end
```

Requests that come through the web server get a correlation ID automatically, so this applies only to scripts and console sessions.

## Inspect OpenBao directly

You can turn on an admin login to browse OpenBao state while debugging.
This requires resetting OpenBao data first.

```shell
gdk stop openbao
gdk reset-openbao-data
gdk config set openbao.admin_enabled true
gdk reconfigure
gdk start openbao
```

Then sign in:

```shell
export BAO_ADDR="http://$(gdk config get openbao.__listen)"
bao login -method=userpass username=admin password=$(cat <gdk-root>/openbao/admin-password.txt)
```

## Reset local data

```shell
gdk stop openbao
gdk reset-openbao-data
gdk start openbao
```

This clears OpenBao state.
After resetting, provision your projects and groups again, for example by rerunning the seed task.

## Troubleshooting

### Secrets Manager is unavailable

`SecretsManagement::Availability.for_project?` returns `false`.
Check the gates individually, as shown in [Step 4](#step-4-verify-your-setup).
On the GDK, the usual cause is that the instance is not enrolled.
See [Step 2](#step-2-enroll-the-instance).

### Provisioning fails with an authentication or keyset error

OpenBao could not fetch the GitLab OIDC discovery document.
Confirm GitLab is serving HTTP at your instance URL, then retry.
Opening `http://gdk.test:3000/` in a browser is a quick check.

### Connection refused when talking to OpenBao

OpenBao is not running.
Run `gdk start openbao` and check `gdk tail openbao` for errors.

### The secrets manager is stuck in the provisioning state

The background worker did not finish.
Run the provision service directly from the Rails console, as shown above, to see the real error.

### Another secret operation is in progress

An exclusive lease is still held.
Wait for it to expire, or cancel it:

```ruby
lease_key = "project_secret_operation:project_#{project.id}"
Gitlab::ExclusiveLease.cancel(lease_key, Gitlab::ExclusiveLease.get_uuid(lease_key))
```

### Path is already in use during provisioning

This message is usually safe.
The secrets engine or auth engine was already mounted, and the provision service handles it.
