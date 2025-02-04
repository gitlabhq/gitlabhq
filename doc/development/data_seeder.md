---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Data Seeder test data harness created by the Test Data Working Group https://handbook.gitlab.com/handbook/company/working-groups/demo-test-data/
title: Data Seeder
---

The Data Seeder is a test data seeding harness, that can seed test data into a user or group namespace.

The Data Seeder uses FactoryBot in the backend which makes maintenance straightforward and future-proof. When a Model changes,
FactoryBot already reflects the change.

## Docker Setup

### With GDK

1. Start a containerized GitLab instance using local files

   ```shell
   docker run \
     -d \
     -p 8080:80 \
     --name gitlab \
     -v ./scripts/data_seeder:/opt/gitlab/embedded/service/gitlab-rails/scripts/data_seeder \
     -v ./ee/db/seeds/data_seeder:/opt/gitlab/embedded/service/gitlab-rails/ee/db/seeds/data_seeder \
     -v ./ee/lib/tasks/gitlab/seed:/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/gitlab/seed \
     -v ./spec:/opt/gitlab/embedded/service/gitlab-rails/spec \
     -v ./ee/spec:/opt/gitlab/embedded/service/gitlab-rails/ee/spec \
     gitlab/gitlab-ee:16.9.8-ee.0
   ```

1. Globalize test gems

   ```shell
   docker exec gitlab bash -c "cd /opt/gitlab/embedded/service/gitlab-rails; ruby scripts/data_seeder/globalize_gems.rb; bundle install"
   ```

1. Seed the data

   ```shell
   docker exec -it gitlab gitlab-rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
   ```

### Without GDK

Requires Git v2.26.0 or later.

1. Start a containerized GitLab instance

   ```shell
   docker run \
     -p 8080:80 \
     --name gitlab \
     -d \
     gitlab/gitlab-ee:16.9.8-ee.0
   ```

1. Import the test resources

   ```ruby
   docker exec gitlab bash -c "wget -O - https://gitlab.com/gitlab-org/gitlab/-/raw/master/scripts/data_seeder/test_resources.sh | bash"
   ```

   ```ruby
   # OR check out a specific branch, commit, or tag
   docker exec gitlab bash -c "wget -O - https://gitlab.com/gitlab-org/gitlab/-/raw/master/scripts/data_seeder/test_resources.sh | REF=v16.7.0-ee bash"
   ```

### Get the root password

To fetch the password for the GitLab instance that was created, execute the following command and use the password given by the output:

```shell
docker exec gitlab cat /etc/gitlab/initial_root_password
```

NOTE:
If you receive `cat: /etc/gitlab/initialize_root_password: No such file or directory`,
please wait for a bit for GitLab to boot and try again.

You can then sign in to `http://localhost:8080/users/sign_in` using the credentials: `root / <Password taken from initial_root_password>`

### Seed the data

**IMPORTANT**: This step should not be executed until the container has started completely and you are able to see the login page at `http://localhost:8080`.

```shell
docker exec -it gitlab gitlab-rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
```

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

The [`ee:gitlab:seed:data_seeder` Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/seed/data_seeder.rake) takes one argument. `:file`.

```shell
$ bundle exec rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
Seeding data for Administrator
....
```

#### `:file`

Where `:file` is the file path. (This path reflects relative `.rb`, `.yml`, or `.json` files located in `ee/db/seeds/data_seeder`, or absolute paths to seed files.)

## Linux package Setup

WARNING:
While it is possible to use the Data Seeder with an Linux package installation, **use caution** if you do this when the instance is being used in a production setting.

Requires Git v2.26.0 or later.

1. Change the working directory to the GitLab installation:

   ```shell
   cd /opt/gitlab/embedded/service/gitlab-rails
   ```

1. Install test resources:

   ```shell
   . scripts/data_seeder/test_resources.sh
   ```

1. Globalize gems:

   ```shell
   /opt/gitlab/embedded/bin/chpst -e /opt/gitlab/etc/gitlab-rails/env /opt/gitlab/embedded/bin/bundle exec ruby scripts/data_seeder/globalize_gems.rb
   ```

1. Install bundle:

   ```shell
   /opt/gitlab/embedded/bin/chpst -e /opt/gitlab/etc/gitlab-rails/env /opt/gitlab/embedded/bin/bundle
   ```

1. Seed the data:

   ```shell
   gitlab-rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
   ```

## Develop

The Data Seeder uses FactoryBot definitions from `spec/factories` which ...

1. Saves time on development
1. Are easy-to-read
1. Are easy to maintain
1. Do not rely on an API that may change in the future
1. Are always up-to-date
1. Executes on the lowest-level possible ([ORM](https://guides.rubyonrails.org/active_record_basics.html#active-record-as-an-orm-framework)) to create data as quickly as possible

> From the [FactoryBot README](https://github.com/thoughtbot/factory_bot#readme_) : `factory_bot` is a fixtures replacement with a straightforward definition syntax, support for multiple build
> strategies (saved instances, unsaved instances, attribute hashes, and stubbed objects), and support for multiple factories for the same class, including factory
> inheritance

Factories reside in `spec/factories/*` and are fixtures for Rails models found in `app/models/*`. For example, For a model named `app/models/issue.rb`, the factory will
be named `spec/factories/issues.rb`. For a model named `app/models/project.rb`, the factory will be named `app/models/projects.rb`.

Three parsers currently exist that the GitLab Data Seeder supports. Ruby, YAML, and JSON.

### Ruby

All Ruby Seeds must define a `DataSeeder` class with a `#seed` instance method. You may structure your Ruby class as you wish. All FactoryBot [methods](https://www.rubydoc.info/gems/factory_bot/FactoryBot/Syntax/Methods) (`create`, `build`, `create_list`) are included in the class automatically and may be called.

The `DataSeeder` class contains the following instance variables defined upon seeding:

- `@seed_file` - The `File` object.
- `@owner` - The owner of the seed data.
- `@name` - The name of the seed. This is the seed file name without the extension.
- `@group` - The top-level group that all seeded data is created under.
- `@logger` - The logger object to log output. Logging output may be found in `log/data_seeder.log`.

```ruby
# frozen_string_literal: true

class DataSeeder
  def seed
    my_group = create(:group, name: 'My Group', path: 'my-group-path', parent: @group)
    @logger.info "Created #{my_group.name}" #=> Created My Group

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

### Logging

When running the Data Seeder, the default level of logging is set to "information".

You can override the logging level by specifying `GITLAB_LOG_LEVEL=<level>`.

```shell
$ GITLAB_LOG_LEVEL=debug bundle exec rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
Seeding data for Administrator
......

$ GITLAB_LOG_LEVEL=warn bundle exec rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
Seeding data for Administrator
......

$ GITLAB_LOG_LEVEL=error bundle exec rake "ee:gitlab:seed:data_seeder[beautiful_data.rb]"
......
```

### Taxonomy of a Factory

Factories consist of three main parts - the **Name** of the factory, the **Traits** and the **Attributes**.

Given: `create(:iteration, :with_title, :current, title: 'My Iteration')`

|                           |  |
|:--------------------------|:-|
| **:iteration**            | This is the **Name** of the factory. The filename will be the plural form of this **Name** and reside under either `spec/factories/iterations.rb` or `ee/spec/factories/iterations.rb`. |
| **:with_title**           | This is a **Trait** of the factory. [See how it's defined](https://gitlab.com/gitlab-org/gitlab/-/blob/9c2a1f98483921dd006d70fdaed316e21fc5652f/ee/spec/factories/iterations.rb#L21-23). |
| **:current**              | This is a **Trait** of the factory. [See how it's defined](https://gitlab.com/gitlab-org/gitlab/-/blob/9c2a1f98483921dd006d70fdaed316e21fc5652f/ee/spec/factories/iterations.rb#L29-31). |
| **title: 'My Iteration'** | This is an **Attribute** of the factory that is passed to the Model for creation. |

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

#### Relate an issue to another Issue

```ruby
create(:project, name: 'My project', namespace: @group, creator: @owner) do |project|
  issue_1 = create(:issue, project:, title: 'Issue 1', description: 'This is issue 1')
  issue_2 = create(:issue, project:, title: 'Issue 2', description: 'This is issue 2')

  create(:issue_link, source: issue_1, target: issue_2)
end
```

### Frequently encountered issues

#### Username or email has already been taken

If you see either of these errors:

- `ActiveRecord::RecordInvalid: Validation failed: Email has already been taken`
- `ActiveRecord::RecordInvalid: Validation failed: Username has already been taken`

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
- IDs that have special characters (`-`, `!`, `$`, `@`, `` ` ``, `=`, `<`, `>`, `;`, `:`)

#### ActiveRecord::AssociationTypeMismatch: Model expected, got ... which is an instance of String

This is a limitation for the seeder.

See the issue for [allowing parsing of raw Ruby objects](https://gitlab.com/gitlab-org/gitlab/-/issues/403079).

## YAML Factories

### Generator to generate _n_ amount of records

### Group Labels

[Group Labels](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/factories/labels.rb):

```yaml
group_labels:
  # Group Label with Name and a Color
  - name: Group Label 1
    group_id: <%= @group.id %>
    color: "#FF0000"
```

### Group Milestones

[Group Milestones](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/factories/milestones.rb):

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

- You _must_ specify `group:` and have it be empty. This is because the Milestones factory manipulates the factory in an `after(:build)`. If this is not present, the Milestone cannot be associated properly with the Group.

### Epics

[Epics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/factories/epics.rb):

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
