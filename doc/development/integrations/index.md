---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "GitLab's development guidelines for Integrations"
---

# Integrations development guidelines

This page provides development guidelines for implementing [GitLab integrations](../../user/project/integrations/index.md),
which are part of our [main Rails project](https://gitlab.com/gitlab-org/gitlab).

Also see our [direction page](https://about.gitlab.com/direction/manage/integrations/) for an overview of our strategy around integrations.

This guide is a work in progress. You're welcome to ping `@gitlab-org/manage/integrations`
if you need clarification or spot any outdated information.

## Add a new integration

### Define the integration

1. Add a new model in `app/models/integrations` extending from `Integration`.
   - For example, `Integrations::FooBar` in `app/models/integrations/foo_bar.rb`.
   - For certain types of integrations, you can also build on these base classes:
     - `Integrations::BaseChatNotification`
     - `Integrations::BaseCi`
     - `Integrations::BaseIssueTracker`
     - `Integrations::BaseMonitoring`
     - `Integrations::BaseSlashCommands`
     - `Integrations::BaseThirdPartyWiki`
   - For integrations that primarily trigger HTTP calls to external services, you can
     also use the `Integrations::HasWebHook` concern. This reuses the [webhook functionality](../../user/project/integrations/webhooks.md)
     in GitLab through an associated `ServiceHook` model, and automatically records request logs
     which can be viewed in the integration settings.
1. Add the integration's underscored name (`'foo_bar'`) to `Integration::INTEGRATION_NAMES`.
1. Add the integration as an association on `Project`:

   ```ruby
   has_one :foo_bar_integration, class_name: 'Integrations::FooBar'
   ```

### Define properties

Integrations can define arbitrary properties to store their configuration with the class method `Integration.prop_accessor`.
The values are stored as an encrypted JSON hash in the `integrations.encrypted_properties` column.

For example:

```ruby
module Integrations
  class FooBar < Integration
    prop_accessor :url
    prop_accessor :tags
  end
end
```

`Integration.prop_accessor` installs accessor methods on the class. Here we would have `#url`, `#url=` and `#url_changed?`, to manage the `url` field. Fields stored in `Integration#properties` should be accessed by these accessors directly on the model, just like other ActiveRecord attributes.

You should always access the properties through their `getters`, and not interact with the `properties` hash directly.
You **must not** write to the `properties` hash, you **must** use the generated setter method instead. Direct writes to this
hash are not persisted.

You should also define validations for all your properties.

Also refer to the section [Customize the frontend form](#customize-the-frontend-form) below to see how these properties
are exposed in the frontend form for the integration.

There is an alternative approach using `Integration.data_field`, which you may see in other integrations.
With data fields the values are stored in a separate table per integration. At the moment we don't recommend using this for new integrations.

### Define trigger events

Integrations are triggered by calling their `#execute` method in response to events in GitLab,
which gets passed a payload hash with details about the event.

The supported events have some overlap with [webhook events](../../user/project/integrations/webhook_events.md),
and receive the same payload. You can specify the events you're interested in by overriding
the class method `Integration.supported_events` in your model.

The following events are supported for integrations:

| Event type                                                                                     | Default | Value                | Trigger
|:-----------------------------------------------------------------------------------------------|:--------|:---------------------|:--
| Alert event                                                                                    |         | `alert`              | A a new, unique alert is recorded.
| Commit event                                                                                   | ✓       | `commit`             | A commit is created or updated.
| [Deployment event](../../user/project/integrations/webhook_events.md#deployment-events)        |         | `deployment`         | A deployment starts or finishes.
| [Issue event](../../user/project/integrations/webhook_events.md#issue-events)                  | ✓       | `issue`              | An issue is created, updated, or closed.
| [Confidential issue event](../../user/project/integrations/webhook_events.md#issue-events)     | ✓       | `confidential_issue` | A confidential issue is created, updated, or closed.
| [Job event](../../user/project/integrations/webhook_events.md#job-events)                      |         | `job`
| [Merge request event](../../user/project/integrations/webhook_events.md#merge-request-events)  | ✓       | `merge_request`      | A merge request is created, updated, or merged.
| [Comment event](../../user/project/integrations/webhook_events.md#comment-events)              |         | `comment`            | A new comment is added.
| [Confidential comment event](../../user/project/integrations/webhook_events.md#comment-events) |         | `confidential_note`  | A new comment on a confidential issue is added.
| [Pipeline event](../../user/project/integrations/webhook_events.md#pipeline-events)            |         | `pipeline`           | A pipeline status changes.
| [Push event](../../user/project/integrations/webhook_events.md#push-events)                    | ✓       | `push`               | A push is made to the repository.
| [Tag push event](../../user/project/integrations/webhook_events.md#tag-events)                 | ✓       | `tag_push`           | New tags are pushed to the repository.
| Vulnerability event **(ULTIMATE)**                                                             |         | `vulnerability`      | A new, unique vulnerability is recorded.
| [Wiki page event](../../user/project/integrations/webhook_events.md#wiki-page-events)          | ✓       | `wiki_page`          | A wiki page is created or updated.

#### Event examples

This example defines an integration that responds to `commit` and `merge_request` events:

```ruby
module Integrations
  class FooBar < Integration
    def self.supported_events
      %w[commit merge_request]
    end
  end
end
```

An integration can also not respond to events, and implement custom functionality some other way:

```ruby
module Integrations
  class FooBar < Integration
    def self.supported_events
      []
    end
  end
end
```

## Define configuration test

Optionally, you can define a configuration test of an integration's settings. The test is executed from the integration form's **Test** button, and results are returned to the user.

A good configuration test:

- Does not change data on the service. For example, it should not trigger a CI build. Sending a message is okay.
- Is meaningful and as thorough as possible.

If it's not possible to follow the above guidelines, consider not adding a configuration test.

To add a configuration test, define a `#test` method for the integration model.

The method receives `data`, which is a test push event payload.
It should return a hash, containing the keys:

- `success` (required): a boolean to indicate if the configuration test has passed.
- `result` (optional): a message returned to the user if the configuration test has failed.

For example:

```ruby
module Integrations
  class FooBar < Integration
    def test(data)
      success = test_api_key(data)

      { success: success, result: 'API key is invalid' }
    end
  end
end
```

### Customize the frontend form

The frontend form is generated dynamically based on metadata defined in the model.

By default, the integration form provides:

- A checkbox to enable or disable the integration.
- Checkboxes for each of the trigger events returned from `Integration#configurable_events`.

You can also add help text at the top of the form by either overriding `Integration#help`,
or providing a template in `app/views/shared/integrations/$INTEGRATION_NAME/_help.html.haml`.

To add your custom properties to the form, you can define the metadata for them in `Integration#fields`.

This method should return an array of hashes for each field, where the keys can be:

| Key            | Type    | Required | Default                      | Description
|:---------------|:--------|:---------|:-----------------------------|:--
| `type:`        | string  | true     |                              | The type of the form field. Can be `text`, `textarea`, `password`, `checkbox`, or `select`.
| `name:`        | string  | true     |                              | The property name for the form field. This must match a `prop_accessor` [defined on the class](#define-properties).
| `required:`    | boolean | false    | `false`                      | Specify if the form field is required or optional.
| `title:`       | string  | false    | Capitalized value of `name:` | The label for the form field.
| `placeholder:` | string  | false    |                              | A placeholder for the form field.
| `help:`        | string  | false    |                              | A help text that displays below the form field.
| `api_only:`    | boolean | false    | `false`                      | Specify if the field should only be available through the API, and excluded from the frontend form.

#### Additional keys for `type: 'checkbox'`

| Key               | Type   | Required | Default           | Description
|:------------------|:-------|:---------|:------------------|:--
| `checkbox_label:` | string | false    | Value of `title:` | A custom label that displays next to the checkbox.

#### Additional keys for `type: 'select'`

| Key        | Type  | Required | Default | Description
|:-----------|:------|:---------|:--------|:--
| `choices:` | array | true     |         | A nested array of `[label, value]` tuples.

#### Additional keys for `type: 'password'`

| Key                         | Type   | Required | Default           | Description
|:----------------------------|:-------|:---------|:------------------|:--
| `non_empty_password_title:` | string | false    | Value of `title:` | An alternative label that displays when a value is already stored.
| `non_empty_password_help:`  | string | false    | Value of `help:`  | An alternative help text that displays when a value is already stored.

#### Frontend form examples

This example defines a required `url` field, and optional `username` and `password` fields:

```ruby
module Integrations
  class FooBar < Integration
    prop_accessor :url, :username, :password

    def fields
      [
        {
          type: 'text',
          name: 'url',
          title: s_('FooBarIntegration|Server URL'),
          placeholder: 'https://example.com/',
          required: true
        },
        {
          type: 'text',
          name: 'username',
          title: s_('FooBarIntegration|Username'),
        },
        {
          type: 'password',
          name: 'password',
          title: s_('FoobarIntegration|Password'
          non_empty_password_title: s_('FooBarIntegration|Enter new password')
        }
      ]
    end
  end
end
```

### Expose the integration in the REST API

To expose the integration in the [REST API](../../api/integrations.md):

1. Add the integration's class (`::Integrations::FooBar`) to `API::Helpers::IntegrationsHelpers.integration_classes`.
1. Add all properties that should be exposed to `API::Helpers::IntegrationsHelpers.integrations`.
1. Update the reference documentation in `doc/api/integrations.md`, add a new section for your integration, and document all properties.

You can also refer to our [REST API style guide](../api_styleguide.md).

Sensitive fields are not exposed over the API. Sensitive fields are those fields that contain any of the following in their name:

- `key`
- `passphrase`
- `password`
- `secret`
- `token`
- `webhook`

## Availability of integrations

By default, integrations are available on the project, group, and instance level.
Most integrations only act in a project context, but can be still configured
from the group and instance levels.

For some integrations it can make sense to only make it available on the project level.
To do that, the integration must be removed from `Integration::INTEGRATION_NAMES` and
added to `Integration::PROJECT_SPECIFIC_INTEGRATION_NAMES` instead.

When developing a new integration, we also recommend you gate the availability behind a
[feature flag](../feature_flags/index.md) in `Integration.available_integration_names`.

## Documentation

You can provide help text in the integration form, including links to off-site documentation,
as described above in [Customize the frontend form](#customize-the-frontend-form). Refer to
our [usability guidelines](https://design.gitlab.com/usability/contextual-help) for help text.

For more detailed documentation, provide a page in `doc/user/project/integrations`,
and link it from the [Integrations overview](../../user/project/integrations/index.md).

You can also refer to our general [documentation guidelines](../documentation/index.md).

## Testing

Testing should not be confused with [defining configuration tests](#define-configuration-test).

It is often sufficient to add tests for the integration model in `spec/models/integrations`,
and a factory with example settings in `spec/factories/integrations.rb`.

Each integration is also tested as part of generalized tests. For example, there are feature specs
that verify that the settings form is rendering correctly for all integrations.

If your integration implements any custom behavior, especially in the frontend, this should be
covered by additional tests.

You can also refer to our general [testing guidelines](../testing_guide/index.md).

## Internationalization

All UI strings should be prepared for translation by following our [internationalization guidelines](../i18n/externalization.md).

The strings should use the integration name as [namespace](../i18n/externalization.md#namespaces), for example, `s_('FooBarIntegration|My string')`.

## Ongoing migrations and refactorings

Developers should be aware that the Integrations team is in the process of
[unifying the way integration properties are defined](https://gitlab.com/groups/gitlab-org/-/epics/3955).

## Integration examples

You can refer to these issues for examples of adding new integrations:

- [Datadog](https://gitlab.com/gitlab-org/gitlab/-/issues/270123): Metrics collector, similar to the Prometheus integration.
- [EWM/RTC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36662): External issue tracker.
- [Shimo](https://gitlab.com/gitlab-org/gitlab/-/issues/343386): External wiki, similar to the Confluence and External Wiki integrations.
- [Webex Teams](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31543): Chat notifications.
- [ZenTao](https://gitlab.com/gitlab-org/gitlab/-/issues/338178): External issue tracker with custom issue views, similar to the Jira integration.
