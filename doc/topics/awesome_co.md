---
stage: Manage
group: Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: AwesomeCo test data harness created by the Test Data Working Group https://about.gitlab.com/company/team/structure/working-groups/demo-test-data/
comments: false
---

# AwesomeCo

AwesomeCo is a test data seeding harness, that can seed test data into a user or group namespace.

AwesomeCo uses FactoryBot in the backend which makes maintenance extremely easy. When a Model is changed,
FactoryBot will already be reflected to account for the change.

## Docker Setup

See [AwesomeCo Docker Demo](https://gitlab.com/-/snippets/2390362)

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

The `ee:gitlab:seed:awesome_co` Rake task takes two arguments. `:name` and `:namespace_id`.

```shell
$ bundle exec rake "ee:gitlab:seed:awesome_co[awesome_co,1]"
Seeding AwesomeCo for Administrator
```

#### `:name`

Where `:name` is the name of the AwesomeCo. (This will reflect .rb files located in db/seeds/awesome_co/*.rb)

#### `:namespace_id`

Where `:namespace_id` is the ID of the User or Group Namespace

## List of Awesome Companies

Each company (i.e. test data template) is represented as a Ruby file (.rb) in `db/seeds/awesome_co`.

### AwesomeCo (db/seeds/awesome_co/awesome_co.rb)

```shell
$ bundle exec rake "ee:gitlab:seed:awesome_co[awesome_co,:namespace_id]"
Seeding AwesomeCo for :namespace_id
```

AwesomeCo is an automated seeding of [this demo repository](https://gitlab.com/tech-marketing/demos/gitlab-agile-demo/awesome-co).

## Develop

AwesomeCo seeding uses FactoryBot definitions from `spec/factories` which ...

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
