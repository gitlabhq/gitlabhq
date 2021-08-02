---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Slack notifications service **(FREE)**

The Slack notifications service enables your GitLab project to send events
(such as issue creation) to your existing Slack team as notifications. Setting up
Slack notifications requires configuration changes for both Slack and GitLab.

You can also use Slack slash commands to control GitLab inside Slack. This is the
separately configured [Slack slash commands](slack_slash_commands.md).

## Slack configuration

1. Sign in to your Slack team and [start a new Incoming WebHooks configuration](https://my.slack.com/services/new/incoming-webhook).
1. Identify the Slack channel where notifications should be sent to by default.
   Select **Add Incoming WebHooks integration** to add the configuration.
1. Copy the **Webhook URL**, which is used later in the GitLab configuration.

## GitLab configuration

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select the **Slack notifications** integration to configure it.
1. In the **Enable integration** section, select the **Active** checkbox.
1. In the **Trigger** section, select the checkboxes for each type of GitLab
   event to send to Slack as a notification. For a full list, see
   [Triggers available for Slack notifications](#triggers-available-for-slack-notifications).
   By default, messages are sent to the channel you configured during
   [Slack integration](#slack-configuration).
1. (Optional) To send messages to a different channel, multiple channels, or as
   a direct message:
   - *To send messages to channels,* enter the Slack channel names, separated by
     commas.
   - *To send direct messages,* use the Member ID found in the user's Slack profile.

   NOTE:
   Usernames and private channels are not supported.

1. In **Webhook**, enter the webhook URL you copied from the previous
   [Slack integration](#slack-configuration) step.
1. (Optional) In **Username**, enter the username of the Slack bot that sends
   the notifications.
1. Select the **Notify only broken pipelines** checkbox to notify only on failures.
1. In the **Branches to be notified** dropdown, select which types of branches
   to send notifications for.
1. Leave the **Labels to be notified** field blank to get all notifications or
   add labels that the issue or merge request must have in order to trigger a
   notification.
1. Select **Test settings** to verify your information, and then select
   **Save changes**.

Your Slack team now starts receiving GitLab event notifications as configured.

### Triggers available for Slack notifications

The following triggers are available for Slack notifications:

| Trigger                | Description |
|------------------------|-------------|
| **Push**               | Triggered by a push to the repository. |
| **Issue**              | Triggered when an issue is created, updated, or closed. |
| **Confidential issue** | Triggered when a confidential issue is created, updated, or closed. |
| **Merge request**      | Triggered when a merge request is created, updated, or merged. |
| **Note**               | Triggered when someone adds a comment. |
| **Confidential note**  | Triggered when someone adds a confidential note. |
| **Tag push**           | Triggered when a new tag is pushed to the repository. |
| **Pipeline**           | Triggered when a pipeline status changes. |
| **Wiki page**          | Triggered when a wiki page is created or updated. |
| **Deployment**         | Triggered when a deployment starts or finishes. |
| **Alert**              | Triggered when a new, unique alert is recorded. |

## Troubleshooting

If your Slack integration is not working, start troubleshooting by
searching through the [Sidekiq logs](../../../administration/logs.md#sidekiqlog)
for errors relating to your Slack service.

### Something went wrong on our end

This is a generic error shown in the GitLab UI and does not mean much by itself.
Review [the logs](../../../administration/logs.md#productionlog) to find
an error message and keep troubleshooting from there.

### `certificate verify failed`

You may see an entry similar to the following in your Sidekiq log:

```plaintext
2019-01-10_13:22:08.42572 2019-01-10T13:22:08.425Z 6877 TID-abcdefg ProjectServiceWorker JID-3bade5fb3dd47a85db6d78c5 ERROR: {:class=>"ProjectServiceWorker", :service_class=>"SlackService", :message=>"SSL_connect returned=1 errno=0 state=error: certificate verify failed"}
```

This is probably a problem either with GitLab communicating with Slack, or GitLab
communicating with itself. The former is less likely, as Slack's security certificates
should _hopefully_ always be trusted. We can establish which we're dealing with by using
the below rails console script.

```shell
# start a rails console:
sudo gitlab-rails console -e production

# or for source installs:
bundle exec rails console -e production
```

```ruby
# run this in the Rails console
# replace <SLACK URL> with your actual Slack URL
result = Net::HTTP.get(URI('https://<SLACK URL>'));0

# replace <GITLAB URL> with your actual GitLab URL
result = Net::HTTP.get(URI('https://<GITLAB URL>'));0
```

If GitLab is not trusting HTTPS connections to itself, then you may
need to [add your certificate to the GitLab trusted certificates](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).

If GitLab is not trusting connections to Slack, then the GitLab
OpenSSL trust store is incorrect. Some typical causes:

- Overriding the trust store with `gitlab_rails['env'] = {"SSL_CERT_FILE" => "/path/to/file.pem"}`.
- Accidentally modifying the default CA bundle `/opt/gitlab/embedded/ssl/certs/cacert.pem`.
