# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class SnippetUserMention < ActiveRecord::Base
          self.table_name = 'snippet_user_mentions'

          def self.resource_foreign_key
            :snippet_id
          end
        end
      end
    end
  end
end
