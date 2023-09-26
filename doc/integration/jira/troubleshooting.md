---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Jira **(FREE ALL)**

This page contains a list of common issues you might encounter when working with Jira integrations.

## GitLab cannot comment on a Jira issue

If GitLab cannot comment on a Jira issue, ensure the Jira user you created for the [Jira issue integration](configure.md) has permission to:

- Post comments on a Jira issue.
- Transition the Jira issue.

When the [GitLab issue tracker](../../integration/external-issue-tracker.md) is disabled, Jira issue references and comments do not work.
If you [restrict IP addresses for Jira access](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), ensure you add your self-managed IP addresses or [GitLab IP addresses](../../user/gitlab_com/index.md#ip-range) to the allowlist in Jira.

For the root cause, check the [`integrations_json.log`](../../administration/logs/index.md#integrations_jsonlog) file. When GitLab tries to comment on a Jira issue, an `Error sending message` log entry might appear.

In GitLab 16.1 and later, when an error occurs, the [`integrations_json.log`](../../administration/logs/index.md#integrations_jsonlog) file contains `client_*` keys in the outgoing API request to Jira.
You can use the `client_*` keys to check the [Atlassian API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-group-issues) for why the error has occurred.

In the following example, Jira responds with a `404` because the Jira issue `ALPHA-1` does not exist:

```json
{
  "severity": "ERROR",
  "time": "2023-07-25T21:38:56.510Z",
  "message": "Error sending message",
  "client_url": "https://my-jira-cloud.atlassian.net",
  "client_path": "/rest/api/2/issue/ALPHA-1",
  "client_status": "404",
  "exception.class": "JIRA::HTTPError",
  "exception.message": "Not Found",
}
```

## GitLab cannot close a Jira issue

If GitLab cannot close a Jira issue:

- Ensure the transition ID you set in the Jira settings matches the one
  your project must have to close an issue. For more information, see
  [automatic issue transitions](issues.md#automatic-issue-transitions) and [custom issue transitions](issues.md#custom-issue-transitions).
- Make sure the Jira issue is not already marked as resolved:
  - Check the Jira issue resolution field is not set.
  - Check the issue is not struck through in Jira lists.

## CAPTCHA

CAPTCHA might be triggered after several consecutive failed login attempts,
which might lead to a `401 unauthorized` error when testing your Jira integration.
If CAPTCHA has been triggered, you can't use the Jira REST API to
authenticate with the Jira site.

To fix this error, sign in to your Jira instance
and complete the CAPTCHA.

## Jira integration does not work for imported project

There is a [known bug](https://gitlab.com/gitlab-org/gitlab/-/issues/341571)
where the Jira integration sometimes does not work for a project that has been imported.
As a workaround, disable the integration and then re-enable it.

## Bulk change all Jira integrations to Jira group-level or instance-level values

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

To change all Jira projects to use instance-level integration settings:

1. In a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session), run the following:

   - In GitLab 15.0 and later:

     ```ruby
     Integrations::Jira.where(active: true, instance: false, inherit_from_id: nil).find_each do |integration|
       default_integration = Integration.default_integration(integration.type, integration.project)

       integration.inherit_from_id = default_integration.id

       if integration.save(context: :manual_change)
         BulkUpdateIntegrationService.new(default_integration, [integration]).execute
       end
     end
     ```

   - In GitLab 14.10 and earlier:

     ```ruby
     jira_integration_instance_id = Integrations::Jira.find_by(instance: true).id
     Integrations::Jira.where(active: true, instance: false, template: false, inherit_from_id: nil).find_each do |integration|
       integration.update_attribute(:inherit_from_id, jira_integration_instance_id)
     end
     ```

1. Modify and save the instance-level integration from the UI to propagate the changes to all group-level and project-level integrations.

## Bulk update the service integration password for all projects

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

To reset the Jira user's password for all projects with active Jira integrations,
run the following in a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN integrations i ON p.id = i.project_id WHERE i.type_new = 'Integrations::Jira' AND i.active = true")

p.each do |project|
  project.jira_integration.update_attribute(:password, '<your-new-password>')
end
```

## `500 We're sorry` when accessing a Jira issue in GitLab

When accessing a Jira issue in GitLab, you might get a `500 We're sorry. Something went wrong on our end` error.
Check [`production.log`](../../administration/logs/index.md#productionlog) to see if it contains the following exception:

```plaintext
:NoMethodError (undefined method 'duedate' for #<JIRA::Resource::Issue:0x00007f406d7b3180>)
```

If that's the case, ensure the [**Due date** field is visible for issues](https://confluence.atlassian.com/jirakb/due-date-field-is-missing-189431917.html) in the integrated Jira project.

## `An error occurred while requesting data from Jira` when viewing the Jira issues list in GitLab

You might see a `An error occurred while requesting data from Jira` message when you attempt to view the Jira issues list in GitLab.

You can see this error when the authentication details in the Jira integration settings are incomplete or incorrect.

To attempt to resolve this error, try [configuring the integration](configure.md#configure-the-integration) again. Verify that the
authentication details are correct, re-enter your API token or password, and save your changes.

## GitLab cannot link to a Jira issue

When you mention a Jira issue ID in GitLab, the issue link might be missing.
[`sidekiq.log`](../../administration/logs/index.md#sidekiq-logs) might contain the following exception:

```plaintext
No Link Issue Permission for issue 'JIRA-1234'
```

To resolve this issue, ensure the Jira user you created for the [Jira issue integration](configure.md) has permission to link issues.
