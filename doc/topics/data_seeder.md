---
stage: Manage
group: Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Data Seeder test data harness created by the Test Data Working Group https://about.gitlab.com/company/team/structure/working-groups/demo-test-data/
---

# GitLab Data Seeder

GitLab Data Seeder (GDS) is a test data seeding harness, that can seed test data into a user or group namespace.

The Data Seeder uses FactoryBot in the backend which makes maintenance extremely easy. When a Model is changed,
FactoryBot will already be reflected to account for the change.

## Docker Setup

See [Data Seeder Docker Demo](https://gitlab.com/-/snippets/2390362)

## GDK Setup

```shell
$ gdk start db
ok: run: services/postgresql: (pid n) 0s, normally down
ok: run: services/redis: (pid n) 74s, normally down
$ bundle install
Bundle complete!
$ bundle exec rake db:migrate
main: migrated
ci: migrated
```

### Run

The `ee:gitlab:seed:data_seeder` Rake task takes two arguments. `:name` and `:namespace_id`.

```shell
$ bundle exec rake "ee:gitlab:seed:data_seeder[data_seeder,1]"
Seeding Data for Administrator
```

#### `:name`

Where `:name` is the file name. (This will reflect relative `.rb`, `.yml`, or `.json` files located in `ee/db/seeds/data_seeder`, or absolute paths to seed files)

#### `:namespace_id`

Where `:namespace_id` is the ID of the User or Group Namespace

## Develop

The Data Seeder uses FactoryBot definitions from `spec/factories` which ...

1. Saves time on development
1. Are easy-to-read
1. Are easy to maintain
1. Do not rely on an API that may change in the future
1. Are always up-to-date
1. Execute on the lowest-level (`ActiveRecord`) possible to create data as quickly as possible

> From the [FactoryBot README](https://github.com/thoughtbot/factory_bot#readme_) : `factory_bot` is a fixtures replacement with a straightforward definition syntax, support for multiple build
> strategies (saved instances, unsaved instances, attribute hashes, and stubbed objects), and support for multiple factories for the same class, including factory
> inheritance

Factories reside in `spec/factories/*` and are fixtures for Rails models found in `app/models/*`. For example, For a model named `app/models/issue.rb`, the factory will
be named `spec/factories/issues.rb`. For a model named `app/models/project.rb`, the factory will be named `app/models/projects.rb`.

There are currently three parsers that the GitLab Data Seeder supports. Ruby, YAML, and JSON.

### Ruby

All Ruby Seeds must define a `DataSeeder` class with a `#seed` instance method. You may structure your Ruby class as you wish. All FactoryBot [methods](https://www.rubydoc.info/gems/factory_bot/FactoryBot/Syntax/Methods) (`create`, `build`, `create_list`) will be included in the class automatically and may be called.

The `DataSeeder` class will have the following instance variables defined upon seeding:

- `@seed_file` - The `File` object.
- `@owner` - The owner of the seed data.
- `@name` - The name of the seed. This will be the seed file name without the extension.
- `@group` - The root group that all seeded data will be created under.

```ruby
# frozen_string_literal: true

class DataSeeder
  def seed
    my_group = create(:group, name: 'My Group', path: 'my-group-path', parent: @group)
    my_project = create(:project, :public, name: 'My Project', namespace: my_group, creator: @owner)
  end
end
```

### YAML

The YAML Parser is a DSL that supports Factory definitions and allows you to seed data using a human-readable format.

```yaml
name: My Seeder
groups:
  - _id: my_group
    name: My Group
    path: my-group-path

projects:
  - _id: my_project
    name: My Project
    namespace_id: <%= groups.my_group.id %>
    creator_id: <%= @owner.id %>
    traits:
      - public
```

### JSON

The JSON Parser allows you to house seed files in JSON format.

```json
{
  "name": "My Seeder",
  "groups": [
    { "_id": "my_group", "name": "My Group", "path": "my-group-path" }
  ],
  "projects": [
    {
      "_id": "my_project",
      "name": "My Project",
      "namespace_id": "<%= groups.my_group.id %>",
      "creator_id": "<%= @owner.id %>",
      "traits": ["public"]
    }
  ]
}
```

### Taxonomy of a Factory

Factories consist of three main parts - the **Name** of the factory, the **Traits** and the **Attributes**.

Given: `create(:iteration, :with_title, :current, title: 'My Iteration')`

|||
|:-|:-|
| **:iteration** | This is the **Name** of the factory. The file name will be the plural form of this **Name** and reside under either `spec/factories/iterations.rb` or `ee/spec/factories/iterations.rb`. |
| **:with_title** | This is a **Trait** of the factory. [See how it's defined](https://gitlab.com/gitlab-org/gitlab/-/blob/9c2a1f98483921dd006d70fdaed316e21fc5652f/ee/spec/factories/iterations.rb#L21-23). |
| **:current** | This is a **Trait** of the factory. [See how it's defined](https://gitlab.com/gitlab-org/gitlab/-/blob/9c2a1f98483921dd006d70fdaed316e21fc5652f/ee/spec/factories/iterations.rb#L29-31). |
| **title: 'My Iteration'** | This is an **Attribute** of the factory that will be passed to the Model for creation. |

### Examples

In these examples, you will see an instance variable `@owner`. This is the `root` user (`User.first`).

#### Create a Group

```ruby
my_group = create(:group, name: 'My Group', path: 'my-group-path')
```

#### Create a Project

```ruby
# create a Project belonging to a Group
my_project = create(:project, :public, name: 'My Project', namespace: my_group, creator: @owner)
```

#### Create an Issue

```ruby
# create an Issue belonging to a Project
my_issue = create(:issue, title: 'My Issue', project: my_project, weight: 2)
```

#### Create an Iteration

```ruby
# create an Iteration under a Group
my_iteration = create(:iteration, :with_title, :current, title: 'My Iteration', group: my_group)
```

### Frequently encountered issues

#### ActiveRecord::RecordInvalid: Validation failed: Email has already been taken, Username has already been taken

This is because, by default, our factories are written to backfill any data that is missing. For instance, when a project
is created, the project must have somebody that created it. If the owner is not specified, the factory attempts to create it.

**How to fix**

Check the respective Factory to find out what key is required. Usually `:author` or `:owner`.

```ruby
# This throws ActiveRecord::RecordInvalid
create(:project, name: 'Throws Error', namespace: create(:group, name: 'Some Group'))

# Specify the user where @owner is a [User] record
create(:project, name: 'No longer throws error', owner: @owner, namespace: create(:group, name: 'Some Group'))
create(:epic, group: create(:group), author: @owner)
```

#### `parsing id "my id" as "my_id"`

See [specifying variables](#specify-a-variable)

#### `id is invalid`

Given that non-Ruby parsers parse IDs as Ruby Objects, the [naming conventions](https://docs.ruby-lang.org/en/2.0.0/syntax/methods_rdoc.html#label-Method+Names) of Ruby must be followed when specifying an ID.

Examples of invalid IDs:

- IDs that start with a number
- IDs that have special characters (-, !, $, @, `, =, <, >, ;, :)

#### ActiveRecord::AssociationTypeMismatch: Model expected, got ... which is an instance of String

This is currently a limitation for the seeder.

See the issue for [allowing parsing of raw Ruby objects](https://gitlab.com/gitlab-org/gitlab/-/issues/403079).

## YAML Factories

### Generator to generate _n_ amount of records

### [Group Labels](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/factories/labels.rb)

```yaml
group_labels:
  # Group Label with Name and a Color
  - name: Group Label 1
    group_id: <%= @group.id %>
    color: "#FF0000"
```

### [Group Milestones](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/factories/milestones.rb)

```yaml
group_milestones:
  # Past Milestone
  - name: Past Milestone
    group_id: <%= @group.id %>
    group:
    start_date: <%= 1.month.ago %>
    due_date: <%= 1.day.ago %>

  # Ongoing Milestone
  - name: Ongoing Milestone
    group_id: <%= @group.id %>
    group:
    start_date: <%= 1.day.ago %>
    due_date: <%= 1.month.from_now %>

  # Future Milestone
  - name: Ongoing Milestone
    group_id: <%= @group.id %>
    group:
    start_date: <%= 1.month.from_now %>
    due_date: <%= 2.months.from_now %>
```

#### Quirks

- You _must_ specify `group:` and have it be empty. This is because the Milestones factory will manipulate the factory in an `after(:build)`. If this is not present, the Milestone will not be associated properly with the Group.

### [Epics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/factories/epics.rb)

```yaml
epics:
  # Simple Epic
  - title: Simple Epic
    group_id: <%= @group.id %>
    author_id: <%= @owner.id %>

  # Epic with detailed Markdown description
  - title: Detailed Epic
    group_id: <%= @group.id %>
    author_id: <%= @owner.id %>
    description: |
      # Markdown

      **Description**

  # Epic with dates
  - title: Epic with dates
    group_id: <%= @group.id %>
    author_id: <%= @owner.id %>
    start_date: <%= 1.day.ago %>
    due_date: <%= 1.month.from_now %>
```

## Variables

Each created factory can be assigned an identifier to be used in future seeding.

You can specify an ID for any created factory that you may use later in the seed file.

### Specify a variable

You may pass an `_id` attribute on any factory to refer back to it later in non-Ruby parsers.

Variables are under the factory definitions that they reside in.

```yaml
---
group_labels:
  - _id: my_label #=> group_labels.my_label

projects:
  - _id: my_project #=> projects.my_project
```

Variables:

NOTE:
It is not advised, but you may specify variables with spaces. These variables may be referred back to with underscores.

### Referencing a variable

Given a YAML seed file:

```yaml
---
group_labels:
  - _id: my_group_label #=> group_labels.my_group_label
    name: My Group Label
    color: "#FF0000"
  - _id: my_other_group_label #=> group_labels.my_other_group_label
    color: <%= group_labels.my_group_label.color %>

projects:
  - _id: my_project #=> projects.my_project
    name: My Project
```

When referring to a variable, the variable refers to the _already seeded_ models. In other words, the model's `id` attribute will
be populated.
