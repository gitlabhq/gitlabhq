<!-- This issue template is used by https://about.gitlab.com/handbook/engineering/development/analytics-section/analytics-instrumentation/ for tracking effort around Service Ping reporting for GitLab.com -->

The [Analytics Instrumentation group](https://about.gitlab.com/handbook/engineering/development/analytics/analytics-instrumentation/) runs manual reporting of ServicePing for GitLab.com on a weekly basis. This issue:

- Captures the work required to complete the reporting process,.
- Captures the follow-up tasks that are focused on metrics performance verification.
- Identifies any potential issues.

# New metrics to be verified

<!-- Add new metrics that must be verified -->

# Failed metrics

Broken metrics issues are marked with the ~"broken metric" label.

# Use a detached screen session to generate Service Ping for GitLab.com

## Prerequisites

1. Add your SSH key to the local SSH agent: `ssh-add`. Your SSH key is required to connect to a Rails console from the bastion host.

## Triggering

1. Add the SSH key to the local SSH agent: `ssh-add`.
1. Connect to the bastion with SSH agent forwarding: `ssh -A lb-bastion.gprd.gitlab.com`.
1. Note which bastion host machine was assigned. For example: `<username>@bastion-01-inf-gprd.c.gitlab-production.internal:~$` shows that you are connected to `bastion-01-inf-gprd.c.gitlab-production.internal`.
1. Create a named screen: `screen -S $USER-service-ping-$(date +%F)`.
1. Connect to the console host: `ssh $USER-rails@console-01-sv-gprd.c.gitlab-production.internal`.
1. Run: `GitlabServicePingWorker.new.perform('triggered_from_cron' => false)`.
1. Press <kbd>Control</kbd>+<kbd>a</kbd> followed by <kbd>Control</kbd>+<kbd>d</kbd> to detach from the screen session.
1. Exit from the bastion: `exit`.

## Verification (After approximately 30 hours)

1. Reconnect to the bastion: `ssh -A lb-bastion.gprd.gitlab.com`. Make sure that you are connected to the same host machine that ServicePing was started on. For example, to connect directly to the host machine, use `ssh bastion-01-inf-gprd.c.gitlab-production.internal`.
1. Find your screen session: `screen -ls`.
1. Attach to your screen session: `screen -x 14226.mwawrzyniak_service_ping_2021_01_22`.
1. Check the last payload in the `raw_usage_data` table: `RawUsageData.last.payload`.
1. Check the when the payload was sent: `RawUsageData.last.sent_at`.

## Stop the Service Ping process

Use either of these processes:

1. Reconnect to the bastion host machine. For example, use: `ssh bastion-01-inf-gprd.c.gitlab-production.internal`.
1. Find your screen session: `$ screen -ls`.
1. Attach to your screen session: `$ sudo -u <username> screen -r`.
1. Press <kbd>Control</kbd>+<kbd>c</kbd> to stop the Service Ping process.

OR

1. Reconnect to the bastion host machine. For example, type: `ssh bastion-01-inf-gprd.c.gitlab-production.internal`.
1. List all process started by your username: `ps faux | grep <username>`.
1. Locate the username that owns ServicePing reporting.
1. Send the kill signal for the ServicePing PID: `kill -9 <service_ping_pid>`.

## Service Ping process triggering (through a long-running SSH session)

1. Connect to the `gprd` Rails console.
1. Run `GitlabServicePingWorker.new.perform('triggered_from_cron' => false)`. This process requires more than 30 hours to complete.
1. Find the last payload in the `raw_usage_data` table: `RawUsageData.last.payload`.
1. Check the when the payload was sent: `RawUsageData.last.sent_at`.

```plaintext
GitlabServicePingWorker.new.perform('triggered_from_cron' => false)

# Get the payload
RawUsageData.last.payload

# Time when payload was sent to VersionsAppp
RawUsageData.last.sent_at
```

# Verify Service Ping in VersionsApp

To verify that the ServicePing was received in the VersionsApp do the following steps:

1. Go to the VersionsApp console and locate: `RawUsageData.find(uuid: '')`.
1. Check the object. Either:
   - Go to the Rails console and check the related `RawUsageData` object.
   - Go to the VersionsApp UI <https://version.gitlab.com/usage_data/usage_data_id>.

```ruby
/bin/herokuish procfile exec rails console

puts UsageData.select(:recorded_at, :app_server_type).where(hostname: 'gitlab.com', uuid: 'ea8bf810-1d6f-4a6a-b4fd-93e8cbd8b57f').order('id desc').limit(5).to_json

puts UsageData.find(21635202).raw_usage_data.payload.to_json
```

# Monitoring events tracked using Redis HLL

Trigger some events from the User Interface.

```ruby
Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'event_name', start_date: 28.days.ago, end_date: Date.current)
```

# Troubleshooting

## Connecting to a Rails console host fails with `Permission denied (publickey).`.

Make sure you add the SSH key to the local SSH agent with: `ssh-add`. If you don't add your SSH key, your key won't be forwarded
when you run `ssh -A`, and you will not be able to connect to a Rails console host.

# What to do if you get mentioned

In this issue, we keep the track of new metrics added to the Service Ping, and the metrics that are timing out.

If you get mentioned, check the failing metric and open an optimization issue.

# Service Ping manual generation for GitLab.com schedule

| Generation start date | GitLab developer handle | Link to comment with payload |
| --------------------- | ----------------------- | ---------------------------- |
| 2022-04-18            |                         |                              |
| 2022-04-25            |                         |                              |
| 2022-05-02            |                         |                              |
| 2022-05-09            |                         |                              |
| 2022-05-16            |                         |                              |

<!-- Do not edit below this line -->

/confidential
/label ~"group::analytics instrumentation" ~"devops::analytics" ~backend ~"section::analytics" ~"Category:Service Ping"
/epic https://gitlab.com/groups/gitlab-org/-/epics/6000
/weight 5
/title Monitor and Generate GitLab.com Service Ping
