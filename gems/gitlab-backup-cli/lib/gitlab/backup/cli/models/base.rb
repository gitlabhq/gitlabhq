# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Models
        class Base < ActiveRecord::Base
          self.abstract_class = true

          def self.initialize_connection!(context:)
            connection_params = Gitlab::Backup::Cli::Services::Postgres.new(context).main_database.connection_params

            establish_connection(connection_params)
          end
        end
      end
    end
  end
end
