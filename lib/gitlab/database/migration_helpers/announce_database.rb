# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module AnnounceDatabase
        extend ActiveSupport::Concern

        def write(text = "")
          if text.present? # announce/say
            super("#{db_config_name}: #{text}")
          else
            super(text)
          end
        end

        def db_config_name
          @db_config_name ||= Gitlab::Database.db_config_name(connection)
        end
      end
    end
  end
end
