# frozen_string_literal: true
# rubocop:disable Style/Documentation

require_relative 'redact_links/redactable'

module Gitlab
  module BackgroundMigration
    class RedactLinks
      class Note < ActiveRecord::Base
        include EachBatch
        include ::Gitlab::BackgroundMigration::RedactLinks::Redactable

        self.table_name = 'notes'
        self.inheritance_column = :_type_disabled
      end

      class Issue < ActiveRecord::Base
        include EachBatch
        include ::Gitlab::BackgroundMigration::RedactLinks::Redactable

        self.table_name = 'issues'
        self.inheritance_column = :_type_disabled
      end

      class MergeRequest < ActiveRecord::Base
        include EachBatch
        include ::Gitlab::BackgroundMigration::RedactLinks::Redactable

        self.table_name = 'merge_requests'
        self.inheritance_column = :_type_disabled
      end

      class Snippet < ActiveRecord::Base
        include EachBatch
        include ::Gitlab::BackgroundMigration::RedactLinks::Redactable

        self.table_name = 'snippets'
        self.inheritance_column = :_type_disabled
      end

      def perform(model_name, field, start_id, stop_id)
        link_pattern = "%/sent_notifications/" + ("_" * 32) + "/unsubscribe%"
        model = "Gitlab::BackgroundMigration::RedactLinks::#{model_name}".constantize

        model.where("#{field} like ?", link_pattern).where(id: start_id..stop_id).each do |resource|
          resource.redact_field!(field)
        end
      end
    end
  end
end
