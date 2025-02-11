---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
<!--- start_remove The following content will be removed on remove_date: '2025-05-15' -->

# Slack notifications (deprecated)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/435909) in GitLab 15.9
and is planned for removal in 19.0. Use the [GitLab for Slack app](gitlab_slack_application.md) instead.
This change is a breaking change.

The Slack notifications integration enables your GitLab project to send events
(such as issue creation) to your existing Slack team as notifications. Setting up
Slack notifications requires configuration changes for both Slack and GitLab.

You can also use [Slack slash commands](slack_slash_commands.md)
to control GitLab from Slack. Slash commands are configured separately.

## Configure Slack

1. Sign in to your Slack team and [start a new Incoming WebHooks configuration](https://my.slack.com/services/new/incoming-webhook).
1. Identify the Slack channel where notifications should be sent to by default.
   Select **Add Incoming WebHooks integration** to add the configuration.
1. Copy the **Webhook URL** to use later when you configure GitLab.

## Configure GitLab

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106760) in GitLab 15.9 to limit Slack channels to 10 per event.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Slack notifications**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In the **Trigger** section, select the checkboxes for each type of GitLab
   event to send to Slack as a notification. For a full list, see
   [Triggers for Slack notifications](#triggers-for-slack-notifications).
   By default, messages are sent to the channel you configured during
   [Slack configuration](#configure-slack).
1. Optional. To send messages to a different channel, multiple channels, or as
   a direct message:
   - *To send messages to channels,* enter the Slack channel names, separated by
     commas.
   - *To send direct messages,* use the Member ID found in the user's Slack profile.
1. In **Webhook**, enter the webhook URL you copied in the
   [Slack configuration](#configure-slack) step.
1. Optional. In **Username**, enter the username of the Slack bot that sends
   the notifications.
1. Select the **Notify only broken pipelines** checkbox to notify only on failures.
1. In the **Branches for which notifications are to be sent** dropdown list, select which types of branches
   to send notifications for.
1. Leave the **Labels to be notified** field blank to get all notifications, or
   add labels that the issue or merge request must have to trigger a
   notification.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

Your Slack team now starts receiving GitLab event notifications as configured.

## Triggers for Slack notifications

The following triggers are available for Slack notifications:

| Trigger name                                                             | Trigger event                                        |
|--------------------------------------------------------------------------|------------------------------------------------------|
| **Push**                                                                 | A push to the repository.                            |
| **Issue**                                                                | An issue is created, closed, or reopened.            |
| **Incident**                                                             | An incident is created, closed, or reopened.         |
| **Confidential issue**                                                   | A confidential issue is created, closed, or reopened.|
| **Merge request**                                                        | A merge request is created, merged, closed, or reopened.|
| **Note**                                                                 | A comment is added.                                  |
| **Confidential note**                                                    | An internal note or comment on a confidential issue is added.|
| **Tag push**                                                             | A new tag is pushed to the repository or removed.    |
| **Pipeline**                                                             | A pipeline status changed.                           |
| **Wiki page**                                                            | A wiki page is created or updated.                   |
| **Deployment**                                                           | A deployment starts or finishes.                     |
| **Alert**                                                                | A new, unique alert is recorded.                     |
| **[Group mention](#trigger-notifications-for-group-mentions) in public**                                              | A group is mentioned in a public context.            |
| **[Group mention](#trigger-notifications-for-group-mentions) in private**                                             | A group is mentioned in a confidential context.      |
| [**Vulnerability**](../../application_security/vulnerabilities/_index.md) | A new, unique vulnerability is recorded.             |

## Trigger notifications for group mentions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/417751) in GitLab 16.4.

To trigger a [notification event](#triggers-for-slack-notifications) for a group mention, use `@<group_name>` in:

- Issue and merge request descriptions
- Comments on issues, merge requests, and commits

## Troubleshooting

If your Slack integration is not working, start troubleshooting by
searching through the [Sidekiq logs](../../../administration/logs/_index.md#sidekiqlog)
for errors relating to your Slack service.

### Error: `Something went wrong on our end`

You might get this generic error message in the GitLab UI.
Review [the logs](../../../administration/logs/_index.md#productionlog) to find
the error message and keep troubleshooting from there.

### Error: `certificate verify failed`

You might see an entry like the following in your Sidekiq log:

```plaintext
2019-01-10_13:22:08.42572 2019-01-10T13:22:08.425Z 6877 TID-abcdefg Integrations::ExecuteWorker JID-3bade5fb3dd47a85db6d78c5 ERROR: {:class=>"Integrations::ExecuteWorker :integration_class=>"SlackService", :message=>"SSL_connect returned=1 errno=0 state=error: certificate verify failed"}
```

This issue occurs when there is a problem with GitLab communicating with Slack,
or GitLab communicating with itself.
The former is less likely, as Slack security certificates should always be trusted.

To view which of these problems is the cause of the issue:

1. Start a Rails console:

   ```shell
   sudo gitlab-rails console -e production

   # for source installs:
   bundle exec rails console -e production
   ```

1. Run the following commands:

   ```ruby
   # replace <SLACK URL> with your actual Slack URL
   result = Net::HTTP.get(URI('https://<SLACK URL>'));0

   # replace <GITLAB URL> with your actual GitLab URL
   result = Net::HTTP.get(URI('https://<GITLAB URL>'));0
   ```

If GitLab does not trust HTTPS connections to itself,
[add your certificate to the GitLab trusted certificates](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates).

If GitLab does not trust connections to Slack,
the GitLab OpenSSL trust store is incorrect. Typical causes are:

- Overriding the trust store with `gitlab_rails['env'] = {"SSL_CERT_FILE" => "/path/to/file.pem"}`.
- Accidentally modifying the default CA bundle `/opt/gitlab/embedded/ssl/certs/cacert.pem`.

### Bulk update to disable the Slack Notification integration

To disable notifications for all projects that have Slack integration enabled,
[start a rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session) and use a script similar to the following:

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
# Grab all projects that have the Slack notifications enabled
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN integrations s ON p.id = s.project_id WHERE s.type_new = 'Integrations::Slack' AND s.active = true")

# Disable the integration on each of the projects that were found.
p.each do |project|
  project.slack_integration.update!(:active, false)
end
```

<!--- end_remove -->
