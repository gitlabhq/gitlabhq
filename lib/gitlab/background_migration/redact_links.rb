# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class RedactLinks
      prepend EE::Gitlab::BackgroundMigration::RedactLinks

      module Redactable
        extend ActiveSupport::Concern

        def redact_field!(field)
          self[field].gsub!(%r{/sent_notifications/\h{32}/unsubscribe}, '/sent_notifications/REDACTED/unsubscribe')

          if self.changed?
            self.update_columns(field => self[field],
                                "#{field}_html" => nil)
          end
        end
      end

      class Note < ActiveRecord::Base
        include EachBatch
        include Redactable

        self.table_name = 'notes'
        self.inheritance_column = :_type_disabled
      end

      class Issue < ActiveRecord::Base
        include EachBatch
        include Redactable

        self.table_name = 'issues'
        self.inheritance_column = :_type_disabled
      end

      class MergeRequest < ActiveRecord::Base
        include EachBatch
        include Redactable

        self.table_name = 'merge_requests'
        self.inheritance_column = :_type_disabled
      end

      class Snippet < ActiveRecord::Base
        include EachBatch
        include Redactable

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
