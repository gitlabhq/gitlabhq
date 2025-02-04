---
stage: Plan
group: Project Management
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Work items widgets
---

## Frontend architecture

Widgets for work items are heavily inspired by [Frontend widgets](fe_guide/widgets.md).
You can expect some differences, because work items are architecturally different from issuables.

GraphQL (Vue Apollo) constitutes the core of work items widgets' stack.

### Retrieve widget information for work items

To display a work item page, the frontend must know which widgets are available
on the work item it is attempting to display. To do so, it needs to fetch the
list of widgets, using a query like this:

```plaintext
query workItem($workItemId: WorkItemID!) {
  workItem(id: $workItemId) {
    id
    widgets {
      ... on WorkItemWidgetAssignees {
        type
        assignees {
          nodes {
            name
          }
        }
      }
    }
  }
}
```

### GraphQL queries and mutations

GraphQL queries and mutations are work item agnostic. Work item queries and mutations
should happen at the widget level, so widgets are standalone reusable components.
The work item query and mutation should support any work item type and be dynamic.
They should allow you to query and mutate any work item attribute by specifying a widget identifier.

In this query example, the description widget uses the query and mutation to
display and update the description of any work item:

```plaintext
query workItem($fullPath: ID!, $iid: String!) {
  workspace: namespace(fullPath: $fullPath) {
    id
    workItem(iid: $iid) {
      id
      iid
      widgets {
        ... on WorkItemWidgetDescription {
          description
          descriptionHtml
        }
      }
    }
  }
}
```

Mutation example:

```plaintext
mutation {
  workItemUpdate(input: {
    id: "gid://gitlab/AnyWorkItem/499"
    descriptionWidget: {
      description: "New description"
    }
  }) {
    errors
    workItem {
      description
    }
  }
}
```

### Widget responsibility and structure

A widget is responsible for displaying and updating a single attribute, such as
title, description, or labels. Widgets must support any type of work item.
To maximize component reusability, widgets should be field wrappers owning the
work item query and mutation of the attribute it's responsible for.

A field component is a generic and simple component. It has no knowledge of the
attribute or work item details, such as input field, date selector, or dropdown list.

Widgets must be configurable to support various use cases, depending on work items.
When building widgets, use slots to provide extra context while minimizing
the use of props and injected attributes.

### Examples

Currently, we have a lot editable widgets which you can find in the [folder](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/work_items/components) namely

- [Work item assignees widget](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/work_item_assignees.vue)
- [Work item labels widget](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/work_item_labels.vue)
- [Work item description widget](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/work_item_description.vue)
...

We also have a [reusable base dropdown widget wrapper](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/shared/work_item_sidebar_dropdown_widget.vue) which can be used for any new widget having a dropdown. It supports both multi select and single select.

## Steps to implement a new work item widget on frontend in the detail view

### Before starting work on a new widget

1. Make sure that you know the scope and have the designs ready for the new widget
1. Check if the new widget is already implemented on the backend and is being returned by the work item query for valid work item types. Due to multiversion compatibility, we should have ~backend and ~frontend in separate milestones.
1. Make sure that the widget update is supported in `workItemUpdate`.
1. Every widget has a different requirement, so asking questions beforehand and creating MVC after discussing with the PM/UX would be a good idea to create iterations on it.

### When we start work on a new widget

1. Depending on the input field i.e a dropdown, input text or any other custom design we should make sure that we use an [existing wrapper](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/shared/work_item_sidebar_dropdown_widget.vue) or completely new component
1. Ideally any new widget should be behind an FF to make sure we have room for testing unless there is a priority for the widget.
1. Create the new widget in the [folder](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/work_items/components)
1. If it is an editable widget in the sidebar , you should include it in [work_item_attributes_wrapper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/work_items/components/work_item_attributes_wrapper.vue)

### Steps

Refer to [merge request #159720](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159720) for an example of the process of adding a new work item widget.

1. Define `I18N_WORK_ITEM_ERROR_FETCHING_<widget_name>` in `app/assets/javascripts/work_items/constants.js`.
1. Create the component `app/assets/javascripts/work_items/components/work_item_<widget_name>.vue` or `ee/app/assets/javascripts/work_items/components/work_item_<widget_name>.vue`.
   - The component should not receive any props which are available from `workItemByIidQuery`- see [issue #461761](https://gitlab.com/gitlab-org/gitlab/-/issues/461761).
1. Add the component to the view/edit work item screen `app/assets/javascripts/work_items/components/work_item_attributes_wrapper.vue`.
1. If the widget is available when creating new work items:
   1. Add the component to the create work item screen `app/assets/javascripts/work_items/components/create_work_item.vue`.
   1. Define a local input type `app/assets/javascripts/work_items/graphql/typedefs.graphql`.
   1. Stub the new work item state GraphQL data for the widget in `app/assets/javascripts/work_items/graphql/cache_utils.js`.
   1. Define how GraphQL updates the GraphQL data in `app/assets/javascripts/work_items/graphql/resolvers.js`.
      - A special `CLEAR_VALUE` constant is required for single value widgets, because we cannot differentiate when a value is `null` because we cleared it, or `null` because we did not
        set it.
        For example `ee/app/assets/javascripts/work_items/components/work_item_health_status.vue`.
        This is not required for most widgets which support multiple values, where we can differentiate between `[]` and `null`.
      - Read more about how [Apollo cache is being used to store values in create view](#apollo-cache-being-used-to-store-values-in-create-view).
1. Add the GraphQL query for the widget:
   - For CE widgets, to `app/assets/javascripts/work_items/graphql/work_item_widgets.fragment.graphql` and `ee/app/assets/javascripts/work_items/graphql/work_item_widgets.fragment.graphql`.
   - For EE widgets, to `ee/app/assets/javascripts/work_items/graphql/work_item_widgets.fragment.graphql`.
1. Update translations: `tooling/bin/gettext_extractor locale/gitlab.pot`.

At this point you should be able to use the widget in the frontend.

Now you can update tests for existing files and write tests for the new files:

1. `spec/frontend/work_items/components/create_work_item_spec.js` or `ee/spec/frontend/work_items/components/create_work_item_spec.js`.
1. `spec/frontend/work_items/components/work_item_attributes_wrapper_spec.js` or `ee/spec/frontend/work_items/components/work_item_attributes_wrapper_spec.js`.
1. `spec/frontend/work_items/components/work_item_<widget_name>_spec.js` or `ee/spec/frontend/work_items/components/work_item_<widget_name>_spec.js`.
1. `spec/frontend/work_items/graphql/resolvers_spec.js` or `ee/spec/frontend/work_items/graphql/resolvers_spec.js`.
1. `spec/features/work_items/work_item_detail_spec.rb` or `ee/spec/features/work_items/work_item_detail_spec.rb`.

NOTE:
You may find some feature specs failing because of excessive SQL queries.
To resolve this, update the mocked `Gitlab::QueryLimiting::Transaction.threshold` in `spec/support/shared_examples/features/work_items/rolledup_dates_shared_examples.rb`.

## Steps to implement a new work item widget on frontend in the create view

1. Make sure that you know the scope and have the designs ready for the new widget
1. Check if the new widget is already implemented on the backend and is being returned by the work item query for valid work item types. Due to multiversion compatibility, we should have ~backend and ~frontend in separate milestones.
1. Make sure that the widget is supported in `workItemCreate` mutation.
1. After you create the new frontend widget based on the designs, make sure to include it in [create work item view](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/work_items/components/create_work_item.vue)

## Apollo cache being used to store values in create view

Since create view is almost identical to detail view, and we wanted to store in the draft data of each widget, each new work item for a specific type has a new cache entry apollo.

For example , when we initialise the create view , we have a function `setNewWorkItemCache` [in work items cache utils](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/graphql/cache_utils) which is called in both [create view work item modal](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/create_work_item_modal.vue) and also [create work item component](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/create_work_item.vue)

You can include the create work item view in any vue file depending on usage. If you pass the `workItemType` of the create view , it will only include the applicable work item widgets which are fetched from [work item types query](../api/graphql/reference/_index.md#workitemtype) and only showing the ones in [widget definitions](../api/graphql/reference/_index.md#workitemwidgetdefinition)

We have a [local mutation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/graphql/update_new_work_item.mutation.graphql) to update the work item draft data in create view

## Support new widget in create form in apollo cache

1. Since every widget can be used separately, each widget uses the `updateWorkItem` mutation.
1. Now, to update the draft data we need to update the cache with the data.
1. Just before you update the work item, we have a check that it is a new work item or a work item `id`/`iid` exists. Example.

```javascript
if (this.workItemId === newWorkItemId(this.workItemType)) {
  this.$apollo.mutate({
    mutation: updateNewWorkItemMutation,
    variables: {
      input: {
        workItemType: this.workItemType,
        fullPath: this.fullPath,
        assignees: this.localAssignees,
      },
    },
});
```

### Support new work item widget in local mutation

1. Add the input type in [work item local mutation typedefs](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/graphql/typedefs.graphql#L55). It can be anything , a custom object or a primitive value.

Example if you want add `parent` which has the name and ID of the parent of the work item

```javascript
input LocalParentWidgetInput {
  id: String
  name: String
}

input LocalUpdateNewWorkItemInput {
  fullPath: String!
  workItemType: String!
  healthStatus: String
  color: String
  title: String
  description: String
  confidential: Boolean
  parent: [LocalParentWidgetInput]
}
```

1. Pass the new parameter from the widget to support draft save in the create view.

```javascript
this.$apollo.mutate({
    mutation: updateNewWorkItemMutation,
    variables: {
      input: {
        workItemType: this.workItemType,
        fullPath: this.fullPath,
        parent: {
          id: 'gid:://gitlab/WorkItem/1',
          name: 'Parent of work item'
        }
      },
    },
})
```

1. Support the update in the [graphql resolver](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/graphql/resolvers.js) and add the logic to update the new work item cache

```javascript
  const { parent } = input;

  if (parent) {
      const parentWidget = findWidget(WIDGET_TYPE_PARENT, draftData?.workspace?.workItem);
      parentWidget.parent = parent;

      const parentWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
        (widget) => widget.type === WIDGET_TYPE_PARENT,
      );
      draftData.workspace.workItem.widgets[parentWidgetIndex] = parentWidget;
  }

```

1. Get the value of the draft in the [create work item view](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/work_items/components/create_work_item.vue)

```javascript

if (this.isWidgetSupported(WIDGET_TYPE_PARENT)) {
    workItemCreateInput.parentWidget = {
      id: this.workItemParentId
    };
}

await this.$apollo.mutate({
  mutation: createWorkItemMutation,
  variables: {
    input: {
      ...workItemCreateInput,
    },
});
```

## Mapping widgets to work item types

All Work Item types share the same pool of predefined widgets and are customized by which widgets are active on a specific type. Because we plan to allow users to create new Work Item types and define a set of widgets for them, mapping of widgets for each Work Item type is stored in database. Mapping of widgets is stored in widget_definitions table and it can be used for defining widgets both for default Work Item types and also in future for custom types. More details about expected database table structure can be found in [this issue description](https://gitlab.com/gitlab-org/gitlab/-/issues/374092).

### Adding new widget to a work item type

Because information about what widgets are assigned to each work item type is stored in database, adding new widget to a work item type needs to be done through a database migration. Also widgets importer (`lib/gitlab/database_importers/work_items/widgets_importer.rb`) should be updated.

### Structure of widget definitions table

Each record in the table defines mapping of a widget to a work item type. Currently only "global" definitions (definitions with NULL `namespace_id`) are used. In next iterations we plan to allow customization of these mappings. For example table below defines that:

- Weight widget is enabled for work item types 0 and 1
- Weight widget is not editable for work item type 1 and only includes the rollup value while work item type 0 only includes the editable value
- in namespace 1 Weight widget is renamed to MyWeight. When user renames widget's name, it makes sense to rename all widget mappings in the namespace - because `name` attribute is denormalized, we have to create namespaced mappings for all work item types for this widget type.
- Weight widget can be disabled for specific work item types (in namespace 3 it's disabled for work item type 0, while still left enabled for work item type 1)

| ID | `namespace_id` | `work_item_type_id` | `widget_type`      | `widget_options`                         | Name         | Disabled |
|:---|:---------------|:--------------------|:-------------------|:-----------------------------------------|:-------------|:---------|
| 1  |                | 0                   | 1                  | {'editable' => true, 'rollup' => false } | Weight       | false    |
| 2  |                | 1                   | 1                  | {'editable' => false, 'rollup' => true } | Weight       | false    |
| 3  | 1              | 0                   | 1                  | {'editable' => true, 'rollup' => false } | MyWeight     | false    |
| 4  | 1              | 1                   | 1                  | {'editable' => false, 'rollup' => true } | MyWeight     | false    |
| 5  | 2              | 0                   | 1                  | {'editable' => true, 'rollup' => false } | Other Weight | false    |
| 6  | 3              | 0                   | 1                  | {'editable' => true, 'rollup' => false } | Weight       | true     |

## Backend architecture

You can update widgets using custom fine-grained mutations (for example, `WorkItemCreateFromTask`) or as part of the
`workItemCreate` or `workItemUpdate` mutations.

### Widget callbacks

When updating the widget together with the work item's mutation, backend code should be implemented using
callback classes that inherit from `WorkItems::Callbacks::Base`. These classes have callback methods
that are named similar to ActiveRecord callbacks and behave similarly.

Callback classes with the same name as the widget are automatically used. For example, `WorkItems::Callbacks::AwardEmoji`
is called when the work item has the `AwardEmoji` widget. To use a different class, you can override the `callback_class`
class method.

When a callback class is also used for other issuables like merge requests or epics, define the class under `Issuable::Callbacks`
and add the class to the list in `IssuableBaseService#available_callbacks`. These are executed for both work item updates and
legacy issue, merge request, or epic updates.

Use `excluded_in_new_type?` to check if the work item type is being changed and a widget is no longer available.
This is typically a trigger to remove associated records which are no longer relevant.

#### Available callbacks

- `after_initialize` is called after the work item is initialized by the `BuildService` and before
  the work item is saved by the `CreateService` and `UpdateService`. This callback runs outside the
  creation or update database transaction.
- `before_create` is called before the work item is saved by the `CreateService`. This callback runs
  within the create database transaction.
- `before_update` is called before the work item is saved by the `UpdateService`. This callback runs
  within the update database transaction.
- `after_create` is called after the work item is saved by the `CreateService`. This callback runs
  within the create database transaction.
- `after_update` is called after the work item is saved by the `UpdateService`. This callback runs
  within the update database transaction.
- `after_save` is called before the creation or DB update transaction is committed by the
  `CreateService` or `UpdateService`.
- `after_update_commit` is called after the DB update transaction is committed by the `UpdateService`.
- `after_save_commit` is called after the creation or DB update transaction is committed by the
  `CreateService` or `UpdateService`.

## Creating a new backend widget

Refer to [merge request #158688](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158688) for an example of the process of adding a new work item widget.

1. Add the widget argument to the work item mutation(s):
   - For CE features where the widget is available and has identical arguments for creating and updating work items: `app/graphql/mutations/concerns/mutations/work_items/shared_arguments.rb`.
   - For EE features, where the widget is only available for one, or the arguments differ between the two mutations:
     - Create: `app/graphql/mutations/concerns/mutations/work_items/create_arguments.rb` or `ee/app/graphql/ee/mutations/work_items/create.rb`.
     - Update: `app/graphql/mutations/concerns/mutations/work_items/update_arguments.rb` or `ee/app/graphql/ee/mutations/work_items/update.rb`.
1. Define the widget arguments, by adding a widget input type in `app/graphql/types/work_items/widgets/<widget_name>_input_type.rb` or `ee/app/graphql/types/work_items/widgets/<widget_name>_input_type.rb`.
   - If the input types differ for the create and update mutations, use `<widget_name>_create_input_type.rb` and/or `<widget_name>_update_input_type.rb`.
1. Define the widget fields, by adding the widget type in `app/graphql/types/work_items/widgets/<widget_name>_type.rb` or `ee/app/graphql/types/work_items/widgets/<widget_name>_type.rb`.
1. Add the widget to the `WorkItemWidget` array in `app/assets/javascripts/graphql_shared/possible_types.json`.
1. Add the widget type mapping to `TYPE_MAPPINGS` in `app/graphql/types/work_items/widget_interface.rb` or `EE_TYPE_MAPPINGS` in `ee/app/graphql/ee/types/work_items/widget_interface.rb`.
1. Add the widget type to `widget_type` enum in `app/models/work_items/widget_definition.rb`.
1. Define the quick actions available as part of the widget in `app/models/work_items/widgets/<widget_name>.rb`.
1. Define how the mutation(s) create/update work items, by adding [callbacks](#widget-callbacks) in `app/services/work_items/callbacks/<widget_name>.rb`.
   - Consider if it is necessary to handle `if excluded_in_new_type?`.
   - Use `raise_error` to handle errors.
1. Define the widget in `WIDGET_NAMES` hash in `lib/gitlab/database_importers/work_items/base_type_importer.rb`.
1. Assign the widget to the appropriate work item types, by:
   - Adding it to the `WIDGETS_FOR_TYPE` hash in `lib/gitlab/database_importers/work_items/base_type_importer.rb`.
   - Creating a migration in `db/migrate/<version>_add_<widget_name>_widget_to_work_item_types.rb`.
     Refer to `db/migrate/20250121163545_add_custom_fields_widget_to_work_item_types.rb` for [the latest best practice](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176206/diffs#diff-content-b6944f559968654c39493bb9f786ee97f12fd370).
     There is no need to use a post-migration, see [discussion on merge request 148119](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148119#note_1837432680).
     See `lib/gitlab/database/migration_helpers/work_items/widgets.rb` if you want to learn more about the structure of the migration.

     ```ruby
     # frozen_string_literal: true

     class AddDesignsAndDevelopmentWidgetsToTicketWorkItemType < Gitlab::Database::Migration[2.2]
       # Include this helper module as it's not included in Gitlab::Database::migration by default
       include Gitlab::Database::MigrationHelpers::WorkItems::Widgets

       restrict_gitlab_migration gitlab_schema: :gitlab_main
       disable_ddl_transaction!
       milestone '17.9'

       WORK_ITEM_TYPE_ENUM_VALUES = 8 # ticket, use [8,9] for multiple types
       # If you want to add one widget, only use one item here.
       WIDGETS = [
         {
           name: 'Designs',
           widget_type: 22
         },
         {
           name: 'Development',
           widget_type: 23
         }
       ]

       def up
         add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
       end

       def down
         remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
       end
     end
     ```

1. Update the GraphQL docs: `bundle exec rake gitlab:graphql:compile_docs`.
1. Update translations: `tooling/bin/gettext_extractor locale/gitlab.pot`.

At this point you should be able to use the [GraphQL query and mutation](#graphql-queries-and-mutations).

Now you can update tests for existing files and write tests for the new files:

1. `spec/graphql/types/work_items/widget_interface_spec.rb` or `ee/spec/graphql/types/work_items/widget_interface_spec.rb`.
1. `spec/models/work_items/widget_definition_spec.rb` or `ee/spec/models/ee/work_items/widget_definition_spec.rb`.
1. `spec/models/work_items/widgets/<widget_name>_spec.rb` or `ee/spec/models/work_items/widgets/<widget_name>_spec.rb`.
1. Request:
   - CE: `spec/requests/api/graphql/mutations/work_items/update_spec.rb` and/or `spec/requests/api/graphql/mutations/work_items/create_spec.rb`.
   - EE: `ee/spec/requests/api/graphql/mutations/work_items/update_spec.rb` and/or `ee/spec/requests/api/graphql/mutations/work_items/create_spec.rb`.
1. Callback: `spec/services/work_items/callbacks/<widget_name>_spec.rb` or `ee/spec/services/work_items/callbacks/<widget_name>_spec.rb`.
1. GraphQL type: `spec/graphql/types/work_items/widgets/<widget_name>_type_spec.rb` or `ee/spec/graphql/types/work_items/widgets/<widget_name>_type_spec.rb`.
1. GraphQL input type(s):
   - CE: `spec/graphql/types/work_items/widgets/<widget_name>_input_type_spec.rb` or `spec/graphql/types/work_items/widgets/<widget_name>_create_input_type_spec.rb` and `spec/graphql/types/work_items/widgets/<widget_name>_update_input_type_spec.rb`.
   - EE: `ee/spec/graphql/types/work_items/widgets/<widget_name>_input_type_spec.rb` or `ee/spec/graphql/types/work_items/widgets/<widget_name>_create_input_type_spec.rb` and `ee/spec/graphql/types/work_items/widgets/<widget_name>_update_input_type_spec.rb`.
1. Migration: `spec/migrations/<version>_add_<widget_name>_widget_to_work_item_types_spec.rb`. Add the shared example that uses the constants from `described_class`.

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'
   require_migration!

   RSpec.describe AddDesignsAndDevelopmentWidgetsToTicketWorkItemType, :migration, feature_category: :team_planning do
     # Tests for `n` widgets in your migration when using the work items widgets migration helper
     it_behaves_like 'migration that adds widgets to a work item type'
   end
   ```
