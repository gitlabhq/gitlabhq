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
