---
stage: Plan
group: Project Management
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---
# Work items widgets

## Frontend architecture

Widgets for work items are heavily inspired by [Frontend widgets](fe_guide/widgets.md).
You can expect some differences, because work items are architecturally different from issuables.

GraphQL (Vue Apollo) constitutes the core of work items widgets' stack.

### Retrieve widget information for work items

To display a work item page, the frontend must know which widgets are available
on the work item it is attempting to display. To do so, it needs to fetch the
list of widgets, using a query like this:

```plaintext
query WorkItem($workItemId: ID!) {
  workItem(workItemId: $id) @client {
    id
    type
    widgets {
      nodes {
        type
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
query {
  workItem(input: {
    workItemId: "gid://gitlab/AnyWorkItem/2207",
    widgetIdentifier: "description",
  }) {
    id
    type
    widgets {
      nodes {
        ... on DescriptionWidget {
          contentText
        }
      }
    }
  }
}

```

Mutation example:

```plaintext
mutation {
  updateWorkItem(input: {
    workItemId: "gid://gitlab/AnyWorkItem/2207",
    widgetIdentifier: "description",
    value: "the updated description"
  }) {
    workItem {
      id
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

We have a [dropdown list component](https://gitlab.com/gitlab-org/gitlab/-/blob/eea9ad536fa2d28ee6c09ed7d9207f803142eed7/app/assets/javascripts/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue)
for use as reference.

Any work item widget can wrap the dropdown list. The widget has knowledge of
the attribute it mutates, and owns the mutation for it. Multiple widgets can use
the same field component. For example:

- Title and description widgets use the input field component.
- Start and end date use the date selector component.
- Labels, milestones, and assignees selectors use the dropdown list.

Some frontend widgets already use the dropdown list. Use them as a reference
for work items widgets development:

- `ee/app/assets/javascripts/boards/components/assignee_select.vue`
- `ee/app/assets/javascripts/boards/components/milestone_select.vue`

## Mapping widgets to work item types

All Work Item types share the same pool of predefined widgets and are customized by which widgets are active on a specific type. Because we plan to allow users to create new Work Item types and define a set of widgets for them, mapping of widgets for each Work Item type is stored in database. Mapping of widgets is stored in widget_definitions table and it can be used for defining widgets both for default Work Item types and also in future for custom types. More details about expected database table structure can be found in [this issue description](https://gitlab.com/gitlab-org/gitlab/-/issues/374092).

### Adding new widget to a work item type

Because information about what widgets are assigned to each work item type is stored in database, adding new widget to a work item type needs to be done through a database migration. Also widgets importer (`lib/gitlab/database_importers/work_items/widgets_importer.rb`) should be updated.

### Structure of widget definitions table

Each record in the table defines mapping of a widget to a work item type. Currently only "global" definitions (definitions with NULL `namespace_id`) are used. In next iterations we plan to allow customization of these mappings. For example table below defines that:

- Weight widget is enabled for work item types 0 and 1
- in namespace 1 Weight widget is renamed to MyWeight. When user renames widget's name, it makes sense to rename all widget mappings in the namespace - because `name` attribute is denormalized, we have to create namespaced mappings for all work item types for this widget type.
- Weight widget can be disabled for specific work item types (in namespace 3 it's disabled for work item type 0, while still left enabled for work item type 1)

| ID | `namespace_id` | `work_item_type_id` | `widget_type_enum` | Position | Name         | Disabled |
|:---|:---------------|:--------------------|:-------------------|:---------|:-------------|:---------|
| 1  |                | 0                   | 1                  | 1        | Weight       | false    |
| 2  |                | 1                   | 1                  | 1        | Weight       | false    |
| 3  | 1              | 0                   | 1                  | 0        | MyWeight     | false    |
| 4  | 1              | 1                   | 1                  | 0        | MyWeight     | false    |
| 5  | 2              | 0                   | 1                  | 1        | Other Weight | false    |
| 6  | 3              | 0                   | 1                  | 1        | Weight       | true     |

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

#### Available callbacks

- `after_initialize` is called after the work item is initialized by the `BuildService` and before
  the work item is saved by the `CreateService` and `UpdateService`. This callback runs outside the
  creation or update database transaction.
- `before_update` is called before the work item is saved by the `UpdateService`. This callback runs
  within the update database transaction.
- `after_update_commit` is called after the DB update transaction is committed by the `UpdateService`.
- `after_save_commit` is called after the creation or DB update transaction is committed by the
  `CreateService` or `UpdateService`.
