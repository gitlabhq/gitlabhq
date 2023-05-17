---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Jira **(FREE)**

This page contains a list of common issues you might encounter when working with Jira integrations.

## GitLab cannot comment on a Jira issue

If GitLab cannot comment on Jira issues, make sure the Jira user you
set up for the [Jira integration](configure.md) has permission to:

- Post comments on a Jira issue.
- Transition the Jira issue.

Jira issue references and update comments do not work if the GitLab issue tracker is disabled.

If you [restrict IP addresses for Jira access](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), make sure you add your self-managed IP addresses or [GitLab.com IP range](../../user/gitlab_com/index.md#ip-range) to the allowlist in Jira.

## GitLab cannot close a Jira issue

If GitLab cannot close a Jira issue:

- Make sure the `Transition ID` you set in the Jira settings matches the one
  your project needs to close an issue.

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

## Bulk change all Jira integrations to Jira instance-level values

To change all Jira projects to use instance-level integration settings:

1. In a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session), run the following:

   ```ruby
   jira_integration_instance_id = Integrations::Jira.find_by(instance: true).id
   Integrations::Jira.where(active: true, instance: false, template: false, inherit_from_id: nil).find_each do |integration|
     integration.update_attribute(:inherit_from_id, jira_integration_instance_id)
   end
   ```

1. Modify and save the instance-level integration from the UI to propagate the changes to all group-level and project-level integrations.

## Check if Jira Cloud is linked

You can use the [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session) to check if Jira Cloud is linked to:

A specified namespace:

```ruby
JiraConnectSubscription.where(namespace: Namespace.by_path('group/subgroup'))
```

A specified project:

```ruby
Project.find_by_full_path('path/to/project').jira_subscription_exists?
```

Any namespace:

```ruby
installation = JiraConnectInstallation.find_by_base_url("https://customer_name.atlassian.net")
installation.subscriptions
```

## Bulk update the service integration password for all projects

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

If that's the case, ensure the **Due date** field is visible for issues in the integrated Jira project.
