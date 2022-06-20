# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module ReestablishedConnectionStack
        # This is workaround for `db:migrate` that switches `ActiveRecord::Base.connection`
        # depending on execution. This is subject to be removed once proper fix is implemented:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/362341
        #
        # In some cases when we run application code we need to restore application connection stack:
        # - ApplicationRecord (in fact ActiveRecord::Base): points to main
        # - Ci::ApplicationRecord: points to ci
        #
        # rubocop:disable Database/MultipleDatabases
        def with_restored_connection_stack(&block)
          original_handler = ActiveRecord::Base.connection_handler

          original_db_config = ActiveRecord::Base.connection_db_config
          if ActiveRecord::Base.configurations.primary?(original_db_config.name)
            return yield(ActiveRecord::Base.connection)
          end

          # If the `ActiveRecord::Base` connection is different than `:main`
          # re-establish and configure `SharedModel` context accordingly
          # to previously established `ActiveRecord::Base` to allow the application
          # code to use `ApplicationRecord` and `Ci::ApplicationRecord` usual way.
          # We swap a connection handler as migration context does hold an actual
          # connection which we cannot close.
          base_model = Gitlab::Database.database_base_models.fetch(original_db_config.name.to_sym)

          # copy connections over to new connection handler
          db_configs = original_handler.connection_pool_names.map do |connection_pool_name|
            [connection_pool_name.constantize, connection_pool_name.constantize.connection_db_config]
          end

          new_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
          ActiveRecord::Base.connection_handler = new_handler

          db_configs.each do |klass, db_config|
            new_handler.establish_connection(db_config, owner_name: klass)
          end

          # re-establish ActiveRecord::Base to main
          ActiveRecord::Base.establish_connection :main # rubocop:disable Database/EstablishConnection

          Gitlab::Database::SharedModel.using_connection(base_model.connection) do
            yield(base_model.connection)
          end
        ensure
          ActiveRecord::Base.connection_handler = original_handler
          new_handler&.clear_all_connections!
        end
        # rubocop:enable Database/MultipleDatabases
      end
    end
  end
end
