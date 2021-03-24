# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class MergeRequestUserMention < ActiveRecord::Base
          self.table_name = 'merge_request_user_mentions'
          self.inheritance_column = :_type_disabled

          def self.resource_foreign_key
            :merge_request_id
          end
        end
      end
    end
  end
end
