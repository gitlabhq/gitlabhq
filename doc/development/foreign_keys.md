# Foreign Keys & Associations

When adding an association to a model you must also add a foreign key. For
example, say you have the following model:

```ruby
class User < ActiveRecord::Base
  has_many :posts
end
```

Here you will need to add a foreign key on column `posts.user_id`. This ensures
that data consistency is enforced on database level. Foreign keys also mean that
the database can very quickly remove associated data (e.g. when removing a
user), instead of Rails having to do this.

## Adding Foreign Keys In Migrations

Foreign keys can be added concurrently using `add_concurrent_foreign_key` as
defined in `Gitlab::Database::MigrationHelpers`. See the [Migration Style
Guide](migration_style_guide.md) for more information.

Keep in mind that you can only safely add foreign keys to existing tables after
you have removed any orphaned rows. The method `add_concurrent_foreign_key`
does not take care of this so you'll need to do so manually.

## Cascading Deletes

Every foreign key must define an `ON DELETE` clause, and in 99% of the cases
this should be set to `CASCADE`.

## Indexes

When adding a foreign key in PostgreSQL the column is not indexed automatically,
thus you must also add a concurrent index. Not doing so will result in cascading
deletes being very slow.

## Dependent Removals

Don't define options such as `dependent: :destroy` or `dependent: :delete` when
defining an association _unless_ the association rows use non database related
data that has to be removed. Even then it's almost always better to add some
custom logic that removes this non database data in bulk, instead of letting
Rails call `destroy` on every associated object.

In other words, this is bad and should only be added when absolutely necessary
and when approved by a database specialist:

```ruby
class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
end
```
