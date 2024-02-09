---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Semantic Versioning of Database Records

[Semantic Versioning](https://semver.org/) of records in a database introduces complexity when it comes to filtering and sorting. Since the database doesn't natively understand semantic versions it is necessary to extract the version components to separate columns in the database. The [SemanticVersionable](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142228) module was introduced to make this process easier.

## Setup Instructions

In order to use SemanticVersionable you must first create a database migration to add the required columns to your table. The required columns are `semver_major`, `semver_minor`, `semver_patch`, and `semver_prerelease`. An example migration would look like this:

```ruby
class AddVersionPartsToModelVersions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_column :ml_model_versions, :semver_major, :integer
    add_column :ml_model_versions, :semver_minor, :integer
    add_column :ml_model_versions, :semver_patch, :integer
    add_column :ml_model_versions, :semver_prerelease, :text
  end

  def down
    remove_column :ml_model_versions, :semver_major, :integer
    remove_column :ml_model_versions, :semver_minor, :integer
    remove_column :ml_model_versions, :semver_patch, :integer
    remove_column :ml_model_versions, :semver_prerelease, :text
  end
end
```

Once the columns are in the database, you can enable the module by including it in your model and configuring it by setting the name of the semver accessor method. For example:

```ruby
module Ml
  class ModelVersion < ApplicationRecord
    include SemanticVersionable

    semver_method :semver

  ...
  end
end
```

The module has two configuation options:

- `semver_method` specifies the name of accessor method that will be added to the objecct
- `validate_semver` is `true` or `false` (defaults to `false`). If true it will throw a validation error if the provided semver string is not in a valid semver format.

Depending on the use case, you may want to disable the validation during the rollout or backfill process.

Please refer to [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142228) as a reference.

## Sorting

The concern provides two scopes to sort by semantic versions:

```ruby
scope :order_by_semantic_version_desc, -> { order(semver_major: :desc, semver_minor: :desc, semver_patch: :desc)}
scope :order_by_semantic_version_asc, -> { order(semver_major: :asc, semver_minor: :asc, semver_patch: :asc)}
```

## Filtering and Searching

TBD
