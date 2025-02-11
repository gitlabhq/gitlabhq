---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "GitLab's development guidelines for Integrations"
title: Integration development guidelines
---

This page provides development guidelines for implementing [GitLab integrations](../../user/project/integrations/_index.md),
which are part of our [main Rails project](https://gitlab.com/gitlab-org/gitlab).

Also see our [direction page](https://about.gitlab.com/direction/manage/import_and_integrate/integrations/) for an overview of our strategy around integrations.

This guide is a work in progress. You're welcome to ping `@gitlab-org/foundations/import-and-integrate`
if you need clarification or spot any outdated information.

## Add a new integration

### Define the integration

1. Add a new model in `app/models/integrations` extending from `Integration`.
   - For example, `Integrations::FooBar` in `app/models/integrations/foo_bar.rb`.
   - For certain types of integrations, you can include these base modules:
     - `Integrations::Base::ChatNotification`
     - `Integrations::Base::Ci`
     - `Integrations::Base::IssueTracker`
     - `Integrations::Base::Monitoring`
     - `Integrations::Base::SlashCommands`
     - `Integrations::Base::ThirdPartyWiki`
   - For integrations that primarily trigger HTTP calls to external services, you can
     also use the `Integrations::HasWebHook` concern. This reuses the [webhook functionality](../../user/project/integrations/webhooks.md)
     in GitLab through an associated `ServiceHook` model, and automatically records request logs
     which can be viewed in the integration settings.
1. Add the integration's underscored name (`'foo_bar'`) to `Integration::INTEGRATION_NAMES`.
1. Add the integration as an association on `Project`:

   ```ruby
   has_one :foo_bar_integration, class_name: 'Integrations::FooBar'
   ```

### Define fields

Integrations can define arbitrary fields to store their configuration with the class method `Integration.field`.
The values are stored as an encrypted JSON hash in the `integrations.encrypted_properties` column.

For example:

```ruby
module Integrations
  class FooBar < Integration
    field :url
    field :tags
  end
end
```

`Integration.field` installs accessor methods on the class.
Here we would have `#url`, `#url=`, and `#url_changed?` to manage the `url` field.
These accessors should access the fields stored in `Integration#properties` directly on the model, just like other `ActiveRecord` attributes.

You should always access the fields through their `getters` and not interact with the `properties` hash directly.
You **must not** write to the `properties` hash, you **must** use the generated setter method instead. Direct writes to this
hash are not persisted.

To see how these fields are exposed in the frontend form for the integration,
see [Customize the frontend form](#customize-the-frontend-form).

Other approaches include using `Integration.prop_accessor` or `Integration.data_field`, which you might see in earlier versions of integrations.
You should not use these approaches for new integrations.

### Define validations

You should define Rails validations for all of your fields.

Validations should only apply when the integration is enabled, by testing the `#activated?` method.

Any field with the [`required:` property](#customize-the-frontend-form) should have a
corresponding validation for `presence`, as the `required:` field property is only for the frontend.

For example:

```ruby
module Integrations
  class FooBar < Integration
    with_options if: :activated? do
      validates :key, presence: true, format: { with: KEY_REGEX }
      validates :bar, inclusion: [true, false]
    end

    field :key, required: true
    field :bar, type: :checkbox
  end
end
```

### Define trigger events

Integrations are triggered by calling their `#execute` method in response to events in GitLab,
which gets passed a payload hash with details about the event.

The supported events have some overlap with [webhook events](../../user/project/integrations/webhook_events.md),
and receive the same payload. You can specify the events you're interested in by overriding
the class method `Integration.supported_events` in your model.

The following events are supported for integrations:

| Event type                                                                                     | Default | Value                | Trigger |
|:-----------------------------------------------------------------------------------------------|:--------|:---------------------|:--|
| Alert event                                                                                    |         | `alert`              | A new, unique alert is recorded. |
| Commit event                                                                                   | ✓       | `commit`             | A commit is created or updated. |
| [Deployment event](../../user/project/integrations/webhook_events.md#deployment-events)        |         | `deployment`         | A deployment starts or finishes. |
| [Work item event](../../user/project/integrations/webhook_events.md#work-item-events)          | ✓       | `issue`              | An issue is created, updated, or closed. |
| [Confidential issue event](../../user/project/integrations/webhook_events.md#work-item-events) | ✓       | `confidential_issue` | A confidential issue is created, updated, or closed. |
| [Job event](../../user/project/integrations/webhook_events.md#job-events)                      |         | `job` | |
| [Merge request event](../../user/project/integrations/webhook_events.md#merge-request-events)  | ✓       | `merge_request`      | A merge request is created, updated, or merged. |
| [Comment event](../../user/project/integrations/webhook_events.md#comment-events)              |         | `comment`            | A new comment is added. |
| [Confidential comment event](../../user/project/integrations/webhook_events.md#comment-events) |         | `confidential_note`  | A new comment on a confidential issue is added. |
| [Pipeline event](../../user/project/integrations/webhook_events.md#pipeline-events)            |         | `pipeline`           | A pipeline status changes. |
| [Push event](../../user/project/integrations/webhook_events.md#push-events)                    | ✓       | `push`               | A push is made to the repository. |
| [Tag push event](../../user/project/integrations/webhook_events.md#tag-events)                 | ✓       | `tag_push`           | New tags are pushed to the repository. |
| Vulnerability event                                                             |         | `vulnerability`      | A new, unique vulnerability is recorded. Ultimate only. |
| [Wiki page event](../../user/project/integrations/webhook_events.md#wiki-page-events)          | ✓       | `wiki_page`          | A wiki page is created or updated. |

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

### Security enhancement features

#### Masking channel values

Integrations that [include from `Integrations::Base::ChatNotification`](#define-the-integration) can hide the
values of their channel input fields. Integrations should hide these values whenever the
fields contain sensitive information such as auth tokens.

By default, `#mask_configurable_channels?` returns `false`. To mask the channel values, override the `#mask_configurable_channels?` method in the integration to return `true`:

```ruby
override :mask_configurable_channels?
def mask_configurable_channels?
  true
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

## Customize the frontend form

The frontend form is generated dynamically based on metadata defined in the model.

By default, the integration form provides:

- A checkbox to enable or disable the integration.
- Checkboxes for each of the trigger events returned from `Integration#configurable_events`.

You can also add help text at the top of the form by either overriding `Integration#help`,
or providing a template in `app/views/shared/integrations/$INTEGRATION_NAME/_help.html.haml`.

To add your custom properties to the form, you can define the metadata for them in `Integration#fields`.

This method should return an array of hashes for each field, where the keys can be:

| Key            | Type    | Required | Default                      | Description |
|:---------------|:--------|:---------|:-----------------------------|:--|
| `type:`        | symbol  | true     | `:text`                      | The type of the form field. Can be `:text`, `:number`, `:textarea`, `:password`, `:checkbox`, `:string_array` or `:select`. |
| `section:`     | symbol  | false    |                              | Specify which section the field belongs to. |
| `name:`        | string  | true     |                              | The property name for the form field. |
| `required:`    | boolean | false    | `false`                      | Specify if the form field is required or optional. Note [backend validations](#define-validations) for presence are still needed. |
| `title:`       | string  | false    | Capitalized value of `name:` | The label for the form field. |
| `placeholder:` | string  | false    |                              | A placeholder for the form field. |
| `help:`        | string  | false    |                              | A help text that displays below the form field. |
| `api_only:`    | boolean | false    | `false`                      | Specify if the field should only be available through the API, and excluded from the frontend form. |
| `description`  | string  | false   |                               | Description of the API field. |
| `if:`          | boolean or lambda | false | `true`                | Specify if the field should be available. The value can be a boolean or a lambda. |

### Additional keys for `type: :checkbox`

| Key               | Type   | Required | Default           | Description |
|:------------------|:-------|:---------|:------------------|:--|
| `checkbox_label:` | string | false    | Value of `title:` | A custom label that displays next to the checkbox. |

### Additional keys for `type: :select`

| Key        | Type  | Required | Default | Description |
|:-----------|:------|:---------|:--------|:--|
| `choices:` | array | true     |         | A nested array of `[label, value]` tuples. |

### Additional keys for `type: :password`

| Key                         | Type   | Required | Default           | Description |
|:----------------------------|:-------|:---------|:------------------|:--|
| `non_empty_password_title:` | string | false    | Value of `title:` | An alternative label that displays when a value is already stored. |
| `non_empty_password_help:`  | string | false    | Value of `help:`  | An alternative help text that displays when a value is already stored. |

### Define sections

All integrations should define `Integration#sections` which split the form into smaller sections,
making it easier for users to set up the integration.

The most commonly used sections are pre-defined and already include some UI:

- `SECTION_TYPE_CONNECTION`: Contains basic fields like `url`, `username`, `password` that are required to connect to and authenticate with the integration.
- `SECTION_TYPE_CONFIGURATION`: Contains more advanced configuration and optional settings around how the integration works.
- `SECTION_TYPE_TRIGGER`: Contains a list of events which will trigger an integration.

`SECTION_TYPE_CONNECTION` and `SECTION_TYPE_CONFIGURATION` render the `dynamic-field` component internally.
The `dynamic-field` component renders a `checkbox`, `number`, `input`, `select`, or `textarea` type for the integration.
For example:

```ruby
module Integrations
  class FooBar < Integration
    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Connection details'),
          description: help
        },
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: _('Configuration'),
          description: s_('Advanced configuration for integration')
        }
      ]
    end
  end
end
```

To add fields to a specific section, you can add the `section:` key to the field metadata.

#### New custom sections

If the existing sections do not meet your requirements for UI customization, you can create new custom sections:

1. Add a new section by adding a new constant `SECTION_TYPE_*` and add it to the `#sections` method:

   ```ruby
   module Integrations
     class FooBar < Integration
       SECTION_TYPE_SUPER = :my_custom_section

       def sections
         [
           {
             type: SECTION_TYPE_SUPER,
             title: s_('Integrations|Custom section'),
             description: s_('Integrations|Help')
           }
         ]
       end
     end
   end
   ```

1. Update the frontend constants `integrationFormSections` and `integrationFormSectionComponents` in `~/integrations/constants.js`.
1. Add your new section component in `app/assets/javascripts/integrations/edit/components/sections/*`.
1. Include and render the new section in `app/assets/javascripts/integrations/edit/components/integration_forms/section.vue`.

### Frontend form examples

This example defines a required `url` field, and optional `username` and `password` fields, all under the `Connection details` section:

```ruby
module Integrations
  class FooBar < Integration
    field :url,
      section: SECTION_TYPE_CONNECTION,
      type: :text,
      title: s_('FooBarIntegration|Server URL'),
      placeholder: 'https://example.com/',
      required: true

    field :username,
      section: SECTION_TYPE_CONNECTION,
      type: :text,
      title: s_('FooBarIntegration|Username')

    field :password,
      section: SECTION_TYPE_CONNECTION,
      type: 'password',
      title: s_('FoobarIntegration|Password'),
      non_empty_password_title: s_('FooBarIntegration|Enter new password')

    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Connection details'),
          description: s_('Integrations|Help')
        }
      ]
    end
  end
end
```

## Expose the integration in the REST API

To expose the integration in the [REST API](../../api/integrations.md):

1. Add the integration's class (`::Integrations::FooBar`) to `API::Helpers::IntegrationsHelpers.integration_classes`.
1. Add the integration's API arguments to `API::Helpers::IntegrationsHelpers.integrations`, for example:

   ```ruby
   'foo-bar' => ::Integrations::FooBar.api_arguments
   ```

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

By default, integrations can apply to a specific project or group, or
to an entire instance.
Most integrations only act in a project context, but can be still configured
for the group and instance.

For some integrations it can make sense to only make it available on certain levels (project, group, or instance).
To do that, the integration must be removed from `Integration::INTEGRATION_NAMES` and instead added to:

- `Integration::PROJECT_LEVEL_ONLY_INTEGRATION_NAMES` to only allow enabling on the project level.
- `Integration::INSTANCE_LEVEL_ONLY_INTEGRATION_NAMES` to only allow enabling on the instance level.
- `Integration::PROJECT_AND_GROUP_LEVEL_ONLY_INTEGRATION_NAMES` to prevent enabling on the instance level.

When developing a new integration, we also recommend you gate the availability behind a
[feature flag](../feature_flags/_index.md) in `Integration.available_integration_names`.

## Documentation

Add documentation for the integration:

- Add a page in `doc/user/project/integrations`.
- Link it from the [Integrations overview](../../user/project/integrations/_index.md).
- After the documentation has merged, [add an entry](../documentation/site_architecture/global_nav.md#add-a-navigation-entry)
  to the documentation navigation under the [Integrations category title](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/24c8ab629383b47a6d6351a9d48325cb43ed5287/content/_data/navigation.yaml?page=3#L2822).

You can also refer to our general [documentation guidelines](../documentation/_index.md).

You can provide help text in the integration form, including links to off-site documentation,
as described above in [Customize the frontend form](#customize-the-frontend-form). Refer to
our [usability guidelines](https://design.gitlab.com/usability/contextual-help) for help text.

## Testing

Testing should not be confused with [defining configuration tests](#define-configuration-test).

It is often sufficient to add tests for the integration model in `spec/models/integrations`,
and a factory with example settings in `spec/factories/integrations.rb`.

Each integration is also tested as part of generalized tests. For example, there are feature specs
that verify that the settings form is rendering correctly for all integrations.

If your integration implements any custom behavior, especially in the frontend, this should be
covered by additional tests.

You can also refer to our general [testing guidelines](../testing_guide/_index.md).

## Internationalization

All UI strings should be prepared for translation by following our [internationalization guidelines](../i18n/externalization.md).

The strings should use the integration name as [namespace](../i18n/externalization.md#namespaces), for example, `s_('FooBarIntegration|My string')`.

## Deprecate and remove an integration

To remove an integration, you must first deprecate the integration. For more information,
see the [feature deprecation guidelines](../deprecation_guidelines/_index.md).

### Deprecate an integration

You must announce any deprecation [no later than the third milestone preceding intended removal](../deprecation_guidelines/_index.md#when-can-a-feature-be-deprecated).
To deprecate an integration:

- [Add a deprecation entry](../deprecation_guidelines/_index.md#update-the-deprecations-and-removals-documentation).
- [Mark the integration documentation as deprecated](../documentation/styleguide/deprecations_and_removals.md).
- Optional. To prevent any new project-level records from
  being created, add the integration to `Project#disabled_integrations` (see [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114835)).

### Remove an integration

To safely remove an integration, you must stage the removal across two milestones.

In the major milestone of intended removal (M.0), disable the integration and delete the records from the database:

- Remove the integration from `Integration::INTEGRATION_NAMES`.
- Delete the integration model's `#execute` and `#test` methods (if defined), but keep the model.
- Add a post-migration to delete the integration records from PostgreSQL (see [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114721)).
- [Mark the integration documentation as removed](../documentation/styleguide/deprecations_and_removals.md#remove-a-page).
- [Update the integration API documentation](../../api/integrations.md).

In the next minor release (M.1):

- Remove the integration's model and any remaining code.
- Close any issues, merge requests, and epics that have the integration's label (`~Integration::<name>`).
- Delete the integration's label (`~Integration::<name>`) from `gitlab-org`.

## Ongoing migrations and refactorings

Developers should be aware that the Integrations team is in the process of
[unifying the way integration properties are defined](https://gitlab.com/groups/gitlab-org/-/epics/3955).

## Integration examples

You can refer to these issues for examples of adding new integrations:

- [Datadog](https://gitlab.com/gitlab-org/gitlab/-/issues/270123): Metrics collector, similar to the Prometheus integration.
- [EWM/RTC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36662): External issue tracker.
- [Webex Teams](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31543): Chat notifications.
- [ZenTao](https://gitlab.com/gitlab-org/gitlab/-/issues/338178): External issue tracker with custom issue views, similar to the Jira issues integration.
