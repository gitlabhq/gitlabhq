# frozen_string_literal: true

# rubocop:disable Style/Documentation
module Gitlab
  module BackgroundMigration
    class DigestColumn
      class PersonalAccessToken < ActiveRecord::Base
        self.table_name = 'personal_access_tokens'
      end

      def perform(model, attribute_from, attribute_to, start_id, stop_id)
        model = model.constantize if model.is_a?(String)

        model.transaction do
          relation = model.where(id: start_id..stop_id).where.not(attribute_from => nil).lock

          relation.each do |instance|
            instance.update_columns(attribute_to => Gitlab::CryptoHelper.sha256(instance.read_attribute(attribute_from)),
                                    attribute_from => nil)
          end
        end
      end
    end
  end
end
