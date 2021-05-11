---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Creating enums

When creating a new enum, it should use the database type `SMALLINT`.
The `SMALLINT` type size is 2 bytes, which is sufficient for an enum.
This would help to save space in the database.

To use this type, add `limit: 2` to the migration that creates the column.

Example:

```ruby
def change
  add_column :ci_job_artifacts, :file_format, :integer, limit: 2
end
```

## All of the key/value pairs should be defined in FOSS

**Summary:** All enums needs to be defined in FOSS, if a model is also part of the FOSS.

```ruby
class Model < ApplicationRecord
  enum platform: {
    aws: 0,
    gcp: 1      # EE-only
  }
end
```

When you add a new key/value pair to a `enum` and if it's EE-specific, you might be
tempted to organize the `enum` as the following:

```ruby
# Define `failure_reason` enum in `Pipeline` model:
class Pipeline < ApplicationRecord
  enum failure_reason: Enums::Pipeline.failure_reasons
end
```

```ruby
# Define key/value pairs that used in FOSS and EE:
module Enums
  module Pipeline
    def self.failure_reasons
      { unknown_failure: 0, config_error: 1 }
    end
  end
end

Enums::Pipeline.prepend_mod_with('Enums::Pipeline')
```

```ruby
# Define key/value pairs that used in EE only:
module EE
  module Enums
    module Pipeline
      override :failure_reasons
      def failure_reasons
        super.merge(activity_limit_exceeded: 2)
      end
    end
  end
end
```

This works as-is, however, it has a couple of downside that:

- Someone could define a key/value pair in EE that is **conflicted** with a value defined in FOSS.
  e.g. Define `activity_limit_exceeded: 1` in `EE::Enums::Pipeline`.
- When it happens, the feature works totally different.
  e.g. We cannot figure out `failure_reason` is either `config_error` or `activity_limit_exceeded`.
- When it happens, we have to ship a database migration to fix the data integrity,
  which might be impossible if you cannot recover the original value.

Also, you might observe a workaround for this concern by setting an offset in EE's values.
For example, this example sets `1000` as the offset:

```ruby
module EE
  module Enums
    module Pipeline
      override :failure_reasons
      def failure_reasons
        super.merge(activity_limit_exceeded: 1_000, size_limit_exceeded: 1_001)
      end
    end
  end
end
```

This looks working as a workaround, however, this approach has some downsides that:

- Features could move from EE to FOSS or vice versa. Therefore, the offset might be mixed between FOSS and EE in the future.
  e.g. When you move `activity_limit_exceeded` to FOSS, you'll see `{ unknown_failure: 0, config_error: 1, activity_limit_exceeded: 1_000 }`.
- The integer column for the `enum` is likely created [as `SMALLINT`](#creating-enums).
  Therefore, you need to be careful of that the offset doesn't exceed the maximum value of 2 bytes integer.

As a conclusion, you should define all of the key/value pairs in FOSS.
For example, you can simply write the following code in the above case:

```ruby
class Pipeline < ApplicationRecord
  enum failure_reason: {
    unknown_failure: 0,
    config_error: 1,
    activity_limit_exceeded: 2
  }
end
```

## Add new values in the gap

After merging some EE and FOSS enums, there might be a gap between the two groups of values:

```ruby
module Enums
  module Ci
    module CommitStatus
      def self.failure_reasons
        {
          # ...
          data_integrity_failure: 12,
          forward_deployment_failure: 13,
          insufficient_bridge_permissions: 1_001,
          downstream_bridge_project_not_found: 1_002,
          # ...
        }
      end
    end
  end
end
```

To add new values, you should fill the gap first.
In the example above add `14` instead of `1_003`:

```ruby
{
  # ...
  data_integrity_failure: 12,
  forward_deployment_failure: 13,
  a_new_value: 14,
  insufficient_bridge_permissions: 1_001,
  downstream_bridge_project_not_found: 1_002,
  # ...
}
```
