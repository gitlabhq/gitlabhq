# frozen_string_literal: true

# Because we use Gitlab::Database, which in turn uses prepend_mod_with,
# we need this intializer to be after config/initializers/0_inject_enterprise_edition_module.rb.

# Post deployment migrations are included by default. This file must be loaded
# before other initializers as Rails may otherwise memoize a list of migrations
# excluding the post deployment migrations.
Gitlab::Database.add_post_migrate_path_to_rails
