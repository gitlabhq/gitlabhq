# frozen_string_literal: true

module Organizations
  module Concerns
    module OrganizationUpdater
      extend ActiveSupport::Concern

      ORGANIZATION_ID_UPDATE_BATCH_SIZE = 1000

      # Update organization_id for records matching the scope specified in the block
      # @param model_class [Class] The ActiveRecord model class
      # @param block Scope to filter records
      #
      # @example Update with hash where clause
      #   update_organization_id_for(PersonalAccessToken) { |relation| relation.where(user_id: [1, 2, 3]) }
      #
      # @example Update with model scopes
      #   update_organization_id_for(PersonalAccessToken) { |relation| relation.where(user_id: user_ids).active }
      #
      # @example Update without a block
      #   update_organization_id_for(PersonalAccessToken)
      #
      # rubocop:disable CodeReuse/ActiveRecord -- Not every model supports `in_organization` scope yet.
      def update_organization_id_for(model_class, &block)
        relation = model_class.where(organization_id: old_organization.id)
        relation = yield(relation) if block

        # Process in batches
        relation.each_batch(of: ORGANIZATION_ID_UPDATE_BATCH_SIZE) do |batch|
          batch.update_all(organization_id: new_organization.id)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
