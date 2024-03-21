---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Jira issue integration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When working with the [Jira issue integration](configure.md), you might encounter the following issues.

## GitLab cannot link to a Jira issue

When you mention a Jira issue ID in GitLab, the issue link might be missing.
[`sidekiq.log`](../../administration/logs/index.md#sidekiq-logs) might contain the following exception:

```plaintext
No Link Issue Permission for issue 'JIRA-1234'
```

To resolve this issue, ensure the Jira user you created for the [Jira issue integration](configure.md) has permission to link issues.

## GitLab cannot comment on a Jira issue

If GitLab cannot comment on a Jira issue, ensure the Jira user you created for the [Jira issue integration](configure.md) has permission to:

- Post comments on a Jira issue.
- Transition the Jira issue.

When the [GitLab issue tracker](../../integration/external-issue-tracker.md) is disabled, Jira issue references and comments do not work.
If you [restrict IP addresses for Jira access](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), ensure you add your self-managed IP addresses or [GitLab IP addresses](../../user/gitlab_com/index.md#ip-range) to the allowlist in Jira.

For the root cause, check the [`integrations_json.log`](../../administration/logs/index.md#integrations_jsonlog) file. When GitLab tries to comment on a Jira issue, an `Error sending message` log entry might appear.

In GitLab 16.1 and later, when an error occurs, the `integrations_json.log` file contains `client_*` keys in the outgoing API request to Jira.
You can use the `client_*` keys to check the [Atlassian API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-group-issues) for why the error has occurred.

In the following example, Jira responds with a `404 Not Found`. This error might happen if:

- The Jira user you created for the Jira issue integration does not have permission to view the issue.
- The Jira issue ID you specified does not exist.

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

For more information about returned status codes, see the [Jira Cloud platform REST API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get-response).

### Using `curl` to verify access to a Jira issue

To verify that a Jira user can access a specific Jira issue, run the following script:

```shell
curl --verbose --user "$USER:$API_TOKEN" "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/2/issue/$JIRA_ISSUE"
```

If the user can access the issue, Jira responds with a `200 OK` and the returned JSON includes the Jira issue details.

## GitLab cannot close a Jira issue

If GitLab cannot close a Jira issue:

- Ensure the transition ID you set in the Jira settings matches the one
  your project must have to close an issue. For more information, see
  [Automatic issue transitions](issues.md#automatic-issue-transitions) and [Custom issue transitions](issues.md#custom-issue-transitions).
- Make sure the Jira issue is not already marked as resolved:
  - Check the Jira issue resolution field is not set.
  - Check the issue is not struck through in Jira lists.

## CAPTCHA after failed sign-in attempts

CAPTCHA might be triggered after consecutive failed sign-in attempts.
These failed attempts might lead to a `401 Unauthorized` when testing the Jira issue integration settings.
If CAPTCHA has been triggered, you cannot use the Jira REST API
to authenticate with the Jira site.

To resolve this issue, sign in to your Jira instance and complete the CAPTCHA.

## Integration does not work for an imported project

The Jira issue integration might not work for a project that has been imported.
For more information, see [issue 341571](https://gitlab.com/gitlab-org/gitlab/-/issues/341571).

To resolve this issue, disable and then re-enable the integration.

## `certificate verify failed` when testing the integration settings

When testing the Jira issue integration settings, you might get the following error:

```plaintext
Connection failed. Check your integration settings. SSL_connect returned=1 errno=0 peeraddr=<jira.example.com> state=error: certificate verify failed (unable to get local issuer certificate)
```

This error might also appear in the [`integrations_json.log`](../../administration/logs/index.md#integrations_jsonlog) file:

```json
{
  "severity":"ERROR",
  "integration_class":"Integrations::Jira",
  "message":"Error sending message",
  "exception.class":"OpenSSL::SSL::SSLError",
  "exception.message":"SSL_connect returned=1 errno=0 peeraddr=x.x.x.x:443 state=error: certificate verify failed (unable to get local issuer certificate)",
}
```

The error occurs because the Jira certificate is not publicly trusted or the certificate chain is incomplete.
Until this issue is resolved, GitLab does not connect to Jira.

To resolve this issue, see
[Common SSL errors](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html#common-ssl-errors).

## Change all Jira projects to instance-level or group-level values

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

### Change all projects on an instance

To change all Jira projects to use instance-level integration settings:

1. In a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session), run the following:

   - In GitLab 15.0 and later:

     ```ruby
     Integrations::Jira.where(active: true, instance: false, inherit_from_id: nil).find_each do |integration|
       default_integration = Integration.default_integration(integration.type, integration.project)

       integration.inherit_from_id = default_integration.id

       if integration.save(context: :manual_change)
         if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
           Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
         else
           BulkUpdateIntegrationService.new(default_integration, [integration]).execute
         end
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

### Change all projects in a group

To change all Jira projects in a group (and its subgroups) to use group-level integration settings:

- In a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session), run the following:

  ```ruby
  def reset_integration(target)
    integration = target.integrations.find_by(type: Integrations::Jira)

    return if integration.nil? # Skip if the project has no Jira issue integration
    return unless integration.inherit_from_id.nil? # Skip integrations that are already inheriting

    default_integration = Integration.default_integration(integration.type, target)

    integration.inherit_from_id = default_integration.id

    if integration.save(context: :manual_change)
      if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
        Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
      else
        BulkUpdateIntegrationService.new(default_integration, [integration]).execute
      end
    end
  end

  parent_group = Group.find_by_full_path('top-level-group') # Add the full path of your top-level group
  current_user = User.find_by_username('admin-user') # Add the username of a user with administrator access

  unless parent_group.nil?
    groups = GroupsFinder.new(current_user, { parent: parent_group, include_parent_descendants: true }).execute

    # Reset any projects in subgroups to use the parent group integration settings
    groups.find_each do |group|
      reset_integration(group)

      group.projects.find_each do |project|
        reset_integration(project)
      end
    end

    # Reset any direct projects in the parent group to use the parent group integration settings
    parent_group.projects.find_each do |project|
      reset_integration(project)
    end
  end
  ```

## Update the integration password for all projects

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

## Jira issue list

When [viewing Jira issues](configure.md#view-jira-issues) in GitLab, you might encounter the following issues.

### `500 We're sorry` when accessing a Jira issue in GitLab

When accessing a Jira issue in GitLab, you might get a `500 We're sorry. Something went wrong on our end` error.
Check [`production.log`](../../administration/logs/index.md#productionlog) to see if the file contains the following exception:

```plaintext
:NoMethodError (undefined method 'duedate' for #<JIRA::Resource::Issue:0x00007f406d7b3180>)
```

If that's the case, ensure the [**Due date** field is visible for issues](https://confluence.atlassian.com/jirakb/due-date-field-is-missing-189431917.html) in the integrated Jira project.

### Error when requesting data from Jira

When you try to view the Jira issue list or create a Jira issue in GitLab, you might get one of the following errors:

```plaintext
An error occurred while requesting data from Jira
```

```plaintext
An error occurred while fetching issue list. Connection failed. Check your integration settings.
```

These errors occur when the authentication for the Jira issue integration is not complete or correct.

To resolve this issue, [configure the Jira issue integration](configure.md#configure-the-integration) again.
Ensure the authentication details are correct, enter your API token or password again, and save your changes.

The Jira issue list does not load if the project key contains a reserved JQL word.
For more information, see [issue 426176](https://gitlab.com/gitlab-org/gitlab/-/issues/426176).
Your Jira project key must not have [restricted words and characters](https://confluence.atlassian.com/jirasoftwareserver/advanced-searching-939938733.html#Advancedsearching-restrictionsRestrictedwordsandcharacters).

### Jira credentials not allowed to access the data

When you try to view the Jira issue list in GitLab, you might get this message:

```plaintext
The credentials for accessing Jira are not allowed to access the data. Check your Jira integration credentials and try again.
```

This error occurs when the Jira credentials cannot access the Jira project key
you specified in the [Jira issue integration](configure.md#configure-the-integration).
To resolve this issue, ensure the Jira user you configured in the Jira issue integration
has permission to view issues associated with the specified Jira project key.

To verify the Jira user has this permission, do one of the following:

- In your browser, sign in to Jira with the user you configured in the Jira issue integration. Because the Jira API supports
  [cookie-based authentication](https://developer.atlassian.com/server/jira/platform/security-overview/#cookie-based-authentication),
  you can see if any issues are returned in the browser:

  ```plaintext
  https://<ATLASSIAN_SUBDOMAIN>.atlassian.net/rest/api/2/search?jql=project=<JIRA PROJECT KEY>
  ```

- Use `curl` for HTTP basic authentication to access the API and see if any issues are returned:

  ```shell
  curl --verbose --user "$USER:$API_TOKEN" "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/2/search?jql=project=$JIRA_PROJECT_KEY" | jq
  ```

Both methods should return a JSON response:

- `total` gives a count of the issues that match the Jira project key.
- `issues` contains an array of the issues that match the Jira project key.

For more information about returned status codes, see the [Jira Cloud platform REST API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get-response).
