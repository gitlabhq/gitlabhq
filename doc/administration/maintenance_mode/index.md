---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab in maintenance mode **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2149) in GitLab Premium 13.9.

In maintenance mode, most write operations are disabled at the application level.
This means that GitLab is effectively in a read-only mode for all non-administrative
users (administrators are still able to edit application settings). Regular users
are able to log in to GitLab, view the interface and perform other read-only
operations, such as `git clone` or `git pull`.

## Enable maintenance mode

There are three ways to enable maintenance mode as an administrator:

- **Web UI**:
  1. Navigate to the **Admin Area > Application settings > General** and toggle
     the maintenance mode. You can optionally add a message for the banner as well.
  1. Click **Save** for the changes to take effect.

- **API**:

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=true"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update_attributes!(maintenance_mode: true)
  ::Gitlab::CurrentSettings.update_attributes!(maintenance_mode_message: "New message")
  ```

## Disable maintenance mode

There are three ways to disable maintenance mode:

- **Web UI**:
  1. Navigate to the **Admin Area > Application settings > General** and toggle
     the maintenance mode. You can optionally add a message for the banner as well.
  1. Click **Save** for the changes to take effect.

- **API**:

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=false"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update_attributes!(maintenance_mode: false)
  ```

## Behavior in maintenance mode

When maintenance mode is enabled, a banner is displayed at the top of the page.
The banner can be customized with a specific message.

An error is displayed when a user tries to perform a write operation that isn't allowed.
The API will return a 403 or 503 error for failed write requests.

NOTE:
In some cases, the visual feedback from an action could be misleading, for example
when starring a project, the **Star** button changes to show the **Unstar** action,
however, this is only the frontend update, and it doesn't take into account the
failed status of the POST request. These visual bugs are to be fixed
[in follow-up iterations](https://gitlab.com/gitlab-org/gitlab/-/issues/295197).

### Application settings

In maintenance mode, admins can edit the application settings. This will allow
them to disable maintenance mode after it's been enabled.

### Logging in/out

All users can log in and out of the GitLab instance.

### CI/CD

In maintenance mode:

- No new jobs are started. Already running jobs stay in 'running'
  status but their logs are no longer updated.
- If the job has been in 'running' state for longer than the project's time limit,
  it will **not** time out.
- Pipelines cannot be started, retried or canceled in maintenance mode.
  No new jobs can be created either.

Once maintenance mode is disabled, new jobs are picked up again. The jobs that were
in the running state before enabling maintenance mode, will resume, and their logs
will start getting updated again.

### Git actions

All read-only Git operations will continue to work in maintenance mode, for example
`git clone` and `git pull`, but all write operations will fail, both through the CLI
and Web IDE.

Geo secondaries are read-only instances that allow Git pushes because they are
proxied to the primary instance. However, in maintenance mode, Git pushes to
both primary and secondaries will fail.

### Merge requests, issues, epics

All write actions except those mentioned above will fail. So, in maintenance mode, a user cannot update merge requests, issues, etc.

### Container Registry

In maintenance mode, `docker push` is blocked, but `docker pull` is available.

### Auto Deploys

It is recommended to disable auto deploys during maintenance mode, and enable
them once maintenance mode is disabled.

### Background jobs

Background jobs (cron jobs, Sidekiq) will continue running as is, because maintenance
mode does not disable any background jobs.

[During a planned Geo failover](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-node),
it is recommended that you disable all cron jobs except for those related to Geo.

You can monitor queues and disable jobs in **Admin Area > Monitoring > Background Jobs**.

### Geo secondaries

The maintenance mode setting will be propagated to the secondary as they sync up.
It is important that you do not disable replication before enabling maintenance mode.

Replication and verification will continue to work in maintenance mode.
