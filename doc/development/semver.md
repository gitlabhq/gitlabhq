---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Semantic Versioning of Database Records
---

[Semantic Versioning](https://semver.org/) of records in a database introduces complexity when it comes to filtering and sorting. Since the database doesn't natively understand semantic versions it is necessary to extract the version components to separate columns in the database. The [SemanticVersionable](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142228) module was introduced to make this process easier.

## Setup Instructions

In order to use SemanticVersionable you must first create a database migration to add the required columns to your table. The required columns are `semver_major`, `semver_minor`, `semver_patch`, and `semver_prerelease`. A `v` prefix can be added to the version by including a column `semver_prefixed`. An example migration would look like this:

```ruby
class AddVersionPartsToModelVersions < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.9'

  def up
    add_column :ml_model_versions, :semver_major, :integer
    add_column :ml_model_versions, :semver_minor, :integer
    add_column :ml_model_versions, :semver_patch, :integer
    add_column :ml_model_versions, :semver_prerelease, :text
    add_column :ml_model_versions, :semver_prefixed, :boolean, default: false
  end

  def down
    remove_column :ml_model_versions, :semver_major, :integer
    remove_column :ml_model_versions, :semver_minor, :integer
    remove_column :ml_model_versions, :semver_patch, :integer
    remove_column :ml_model_versions, :semver_prerelease, :text
    remove_column :ml_model_versions, :semver_prefixed, :boolean
  end
end
```

Once the columns are in the database, you can enable the module by including it in your model. For example:

```ruby
module Ml
  class ModelVersion < ApplicationRecord
    include SemanticVersionable
  ...
  end
end
```

The module is configured to validate a semantic version by default.

## Sorting

The concern provides two scopes to sort by semantic versions:

```ruby
scope :order_by_semantic_version_desc, -> { order(semver_major: :desc, semver_minor: :desc, semver_patch: :desc)}
scope :order_by_semantic_version_asc, -> { order(semver_major: :asc, semver_minor: :asc, semver_patch: :asc)}
```

## Filtering and Searching

TBD
