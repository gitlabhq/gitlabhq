---
stage: Plan
group: Project Management
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Fixed items model
---

Use `ActiveRecord::FixedItemsModel` to define static, read-only data in code
instead of database tables. Instances behave like ActiveRecord objects but are
stored in memory with deterministic, version-controlled IDs.

This pattern replaces database-backed lookup tables where:

- Data is static and changes only through code deployments.
- Globally consistent IDs are required across [Cells](cells/_index.md).
- Zero database queries are acceptable for lookups.

## When to use

Use `FixedItemsModel` when:

- The data is defined in code and changes only through deployments.
- IDs must be identical across all Cells and environments.
- The data does not change at runtime (no user-created records).

The dataset does not have to be small or statically defined. Use the
`.fixed_items` class method to compute items dynamically from other sources.
For example, `WidgetDefinition` generates its items by iterating all work
item types and their widget configurations. Use `auto_generate_ids!` when
the items don't need stable IDs for the persistence layer.

Do not use `FixedItemsModel` when:

- Users or admins can create, update, or delete records at runtime.
- Records need database-level associations such as `has_many` or `has_many :through`.

## Cells architecture context

Database tables with auto-incrementing sequences produce different IDs on
different Cells for the same logical entity. Cross-cell references break
because Cell A's `plan_id = 4` might mean `premium` while Cell B's
`plan_id = 4` might mean `gold`.

`FixedItemsModel` solves this by hard-coding IDs in application code. Every
Cell loads the same definitions and produces the same IDs. For more details,
see the [static data section of the Cells development guidelines](cells/_index.md#static-data).

## Basic usage

### Define a model with an `ITEMS` constant

The simplest pattern defines items inline:

```ruby
module Security
  class StaticTrainingProvider
    include ActiveRecord::FixedItemsModel::Model

    ITEMS = [
      { id: 1, name: "Kontra", url: "https://application.security/api/webhook/gitlab/exercises/search" },
      { id: 2, name: "Secure Code Warrior", url: "https://integration-api.securecodewarrior.com/api/v1/trial" },
      { id: 3, name: "SecureFlag", url: "https://knowledge-base-api.secureflag.com/gitlab" }
    ].freeze

    attribute :name, :string
    attribute :url, :string
  end
end
```

Each item must have an `id` key with a positive integer value. Declare each
non-ID attribute with `attribute`. The `id` attribute is declared automatically.

You must use either an `ITEMS` constant or a `.fixed_items` class method, not both.

### Define a model with `.fixed_items`

Use a class method when items are derived from other sources:

```ruby
module WorkItems
  module TypesFramework
    module SystemDefined
      class Type
        include ActiveRecord::FixedItemsModel::Model

        attribute :name, :string
        attribute :base_type, :string
        attribute :icon_name, :string

        class << self
          def fixed_items
            [
              Definitions::Issue.configuration,
              Definitions::Incident.configuration,
              Definitions::Task.configuration,
              Definitions::Ticket.configuration
            ]
          end
        end
      end
    end
  end
end
```

Each definition class returns a hash with `id`, `name`, `base_type`, and
`icon_name` keys. This pattern keeps the data definition close to the
domain logic for each type.

### Auto-generate IDs

Use `auto_generate_ids!` when items don't need stable, externally-referenced IDs.
IDs are assigned sequentially starting at 1 based on array order. This is useful
when you need the ActiveRecord-like query interface (`find_by`, `where`, `all`)
but the objects are internal and their IDs are never persisted or exposed through
an API.

`WidgetDefinition` is a good example. It dynamically generates its items from all
work item types and their widget configurations. The IDs are throwaway handles —
what matters is the combination of `widget_type` and `work_item_type_id`:

```ruby
class WidgetDefinition
  include ActiveRecord::FixedItemsModel::Model
  include ActiveRecord::FixedItemsModel::HasOne

  auto_generate_ids!

  attribute :widget_type, :string
  attribute :work_item_type_id, :integer

  belongs_to_fixed_items :work_item_type,
    fixed_items_class: WorkItems::TypesFramework::SystemDefined::Type

  class << self
    def fixed_items
      Type.all.flat_map do |type|
        type.configuration_class.widgets.map do |widget_type|
          { widget_type: widget_type.to_s, work_item_type_id: type.id }
        end
      end
    end
  end
end
```

> [!note]
> With `auto_generate_ids!`, changing the order of items changes their IDs.
> Do not use this when IDs are stored in the database or referenced externally.

When assigning explicit IDs, reserve ID ranges if multiple teams might add
items independently. For example, work item types use IDs 1-9 for
system-defined types and 1001+ for custom types stored in the database.

## Query items

`FixedItemsModel` provides an ActiveRecord-like query interface:

```ruby
# Find by ID (raises RecordNotFound if not found)
Security::StaticTrainingProvider.find(1)

# Find by attributes (returns nil if not found)
Security::StaticTrainingProvider.find_by(name: "Kontra")

# Filter by attributes (returns an array)
Security::StaticTrainingProvider.where(name: "Kontra")

# All items
Security::StaticTrainingProvider.all

# Iterate
Security::StaticTrainingProvider.find_each { |provider| puts provider.name }
```

The `where` method supports multiple conditions and array values:

```ruby
WorkItems::TypesFramework::SystemDefined::Type.where(base_type: %w[issue incident])
WorkItems::TypesFramework::SystemDefined::Type.where(base_type: :issue, icon_name: 'issue-type-issue')
```

Chaining is not supported. The `where` method returns an `Array`, not a
relation. Pass all conditions to a single `where` call, or add class methods
on the model for sorting, ordering, or other query logic.

Items are loaded into an in-memory cache on first access and reused for
the lifetime of the process. Repeated calls to `.find` or `.find_by` with
the same ID return the same object instance (identity equality, not just
value equality):

```ruby
a = WorkItems::TypesFramework::SystemDefined::Type.find(1)
b = WorkItems::TypesFramework::SystemDefined::Type.find(1)
a.equal?(b) # => true, same object in memory
```

## Associations with ActiveRecord models

Use `ActiveRecord::FixedItemsModel::HasOne` to create a `belongs_to`-style
association from an ActiveRecord model to a fixed items model.

### Basic association

```ruby
class CurrentStatus < ApplicationRecord
  include ActiveRecord::FixedItemsModel::HasOne

  belongs_to_fixed_items :system_defined_status,
    fixed_items_class: WorkItems::Statuses::SystemDefined::Status,
    foreign_key: 'system_defined_status_identifier'
end
```

The association provides getter, setter, and query methods:

```ruby
status = CurrentStatus.last
status.system_defined_status                   # Returns the fixed items model instance
status.system_defined_status = Status.find(2)  # Sets via object
status.system_defined_status_identifier = 2    # Sets via column
status.system_defined_status?                  # Returns true if present
```

### Column naming: use `_identifier`, not `_id`

Name the database column `<association>_identifier` rather than
`<association>_id`. In PostgreSQL, `_id` columns conventionally imply a
foreign key with database-level integrity constraints.
Fixed items models live in memory, so the database cannot enforce
referential integrity on these columns. Using `_identifier` makes this
distinction explicit.

Always pass `foreign_key:` to `belongs_to_fixed_items` to use the
`_identifier` column name:

```ruby
class CustomType < ApplicationRecord
  include ActiveRecord::FixedItemsModel::HasOne

  belongs_to_fixed_items :converted_from_type,
    fixed_items_class: WorkItems::TypesFramework::SystemDefined::Type,
    foreign_key: 'converted_from_system_defined_type_identifier'
end
```

### Caching behavior

The association caches the resolved object and invalidates automatically when
the foreign key changes. The cache is also cleared when `reset` is called on
the ActiveRecord model.

## GlobalID support

To use a fixed items model with GraphQL or any other system that relies on
`GlobalID`, include `GlobalID::Identification`:

```ruby
class Type
  include ActiveRecord::FixedItemsModel::Model
  include GlobalID::Identification

  # Optional: Override if the GlobalID model name must differ from the class name
  def to_global_id(_options = {})
    ::Gitlab::GlobalId.build(self, model_name: 'WorkItems::Type', id: id)
  end
  alias_method :to_gid, :to_global_id
end
```

## JSON serialization

Instances support `as_json` and `to_json` with `:only`, `:except`, and
`:methods` options:

```ruby
provider = Security::StaticTrainingProvider.find(1)

provider.as_json(only: [:id, :name])
# => {"id"=>1, "name"=>"Kontra"}

provider.as_json(except: [:url])
# => {"id"=>1, "name"=>"Kontra", "description"=>"..."}

provider.as_json(methods: [:some_computed_method])
```

## Object behavior

Fixed items model instances behave as persisted, read-only records:

| Method | Return value |
| ------ | ------------ |
| `persisted?` | `true` |
| `new_record?` | `false` |
| `readonly?` | `true` |
| `changed?` | `false` |
| `destroyed?` | `false` |

Two instances are equal if they are the same class and have the same `id`.

## Error handling

The module defines two custom error classes:

- `ActiveRecord::FixedItemsModel::RecordNotFound` — raised by `.find` when no
  item matches the given ID.
- `ActiveRecord::FixedItemsModel::UnknownAttribute` — raised by `.find_by` or
  `.where` when a query references an attribute that is not declared.

Handle `RecordNotFound` the same way you would handle
`ActiveRecord::RecordNotFound` in controllers or services.

## Validations

Instances support `ActiveModel::Validations`. Add validations the same way as
with any ActiveModel class:

```ruby
class WidgetDefinition
  include ActiveRecord::FixedItemsModel::Model

  attribute :widget_type, :string
  attribute :work_item_type_id, :integer

  validates :widget_type, presence: true
  validates :work_item_type_id, presence: true
end
```

Items are validated at load time. An invalid item definition raises an error
during the first call to `.all`.

## Testing

### Factory pattern

Use `build`, not `create`. Fixed items models live in memory, so the
`create` semantic (persist to database) does not apply. Factories use
`skip_create` and `initialize_with` to return the actual in-memory object
rather than constructing a detached instance:

```ruby
FactoryBot.define do
  factory :work_item_system_defined_type, class: 'WorkItems::TypesFramework::SystemDefined::Type' do
    skip_create
    issue

    initialize_with do
      WorkItems::TypesFramework::SystemDefined::Type.find(attributes[:id] || 1)
    end

    trait :issue do
      id { 1 }
      base_type { 'issue' }
    end

    trait :incident do
      id { 2 }
      base_type { 'incident' }
    end
  end
end
```

`build(:work_item_system_defined_type, :issue)` returns the same object as
`Type.find(1)`. This means specs operate on the real in-memory instances,
not detached copies.

### Writing specs

Test fixed items models the same way you test ActiveRecord models: verify
validations, class methods, instance methods, and GlobalID integration.
The difference is that you always work with a specific in-memory object
rather than an unpersisted `subject`:

```ruby
let(:type) { build(:work_item_system_defined_type) }

it 'has name attribute' do
  expect(type.name).to eq('Issue')
end
```

For models without a factory, call query methods directly:

```ruby
let(:provider) { Security::StaticTrainingProvider.find(1) }
```

## Contribute

The `FixedItemsModel` implementation is part of the `activerecord-gitlab` gem.
For questions or changes, reach out to the Project Management group in the
Plan stage through [`#g_project-management`](https://gitlab.enterprise.slack.com/archives/g_project-management)
or [`#s_plan`](https://gitlab.enterprise.slack.com/archives/s_plan) on Slack.

### Key files

| File | Purpose |
| ---- | ------- |
| `gems/activerecord-gitlab/lib/active_record/fixed_items_model/model.rb` | Core module: query interface, storage, validation, serialization |
| `gems/activerecord-gitlab/lib/active_record/fixed_items_model/has_one.rb` | Association support: `belongs_to_fixed_items`, caching |
| `gems/activerecord-gitlab/spec/active_record/fixed_items_model/model_spec.rb` | Specs for the core module |
| `gems/activerecord-gitlab/spec/active_record/fixed_items_model/has_one_spec.rb` | Specs for association support |

### Run gem specs

The gem has its own dependency set. Install and run specs from the gem
directory:

```shell
cd gems/activerecord-gitlab
bundle install
bundle exec rspec spec/active_record/fixed_items_model/
```

## Production examples

| Model | Domain | Pattern | Complexity |
| ----- | ------ | ------- | ---------- |
| [`Security::StaticTrainingProvider`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/security/static_training_provider.rb) | Security training | `ITEMS` constant | Simple |
| [`WorkItems::Statuses::SystemDefined::Status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/work_items/statuses/system_defined/status.rb) | Work item statuses | `ITEMS` constant, associations | Medium |
| [`Ai::FoundationalChatAgent`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/ai/foundational_chat_agent.rb) | AI agents | `ITEMS` constant, GlobalID, custom queries | Medium |
| [`WorkItems::TypesFramework::SystemDefined::Type`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/work_items/types_framework/system_defined/type.rb) | Work item types | `.fixed_items`, GlobalID, dynamic predicates | Complex |
| [`WorkItems::TypesFramework::SystemDefined::WidgetDefinition`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/work_items/types_framework/system_defined/widget_definition.rb) | Widget configs | `auto_generate_ids!`, `.fixed_items`, associations | Complex |

## Related topics

- [Cells development guidelines: static data](cells/_index.md#static-data)
- [Work items and work item types](work_items.md)
- [Configurable Work Item Types design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/configurable_work_item_types/)
- [Work Items Custom Status design document: Fixed items models and associations](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items_custom_status/#fixed-items-models-and-associations)
- [Work Item Framework Engineering Vision](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items_framework_vision/)
- [Update work item developer documentation](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225549)
