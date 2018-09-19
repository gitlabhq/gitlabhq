# frozen_string_literal: true

# Provides a way to work around Rails issue where dependent objects are all
# loaded into memory before destroyed: https://github.com/rails/rails/issues/22510.
#
# This concern allows an ActiveRecord module to destroy all its dependent
# associations in batches. The idea is borrowed from https://github.com/thisismydesign/batch_dependent_associations.
#
# The differences here with that gem:
#
# 1. We allow excluding certain associations.
# 2. We don't need to support delete_all since we can use the EachBatch concern.
module BatchDestroyDependentAssociations
  extend ActiveSupport::Concern

  DEPENDENT_ASSOCIATIONS_BATCH_SIZE = 1000

  def dependent_associations_to_destroy
    self.class.reflect_on_all_associations(:has_many).select { |assoc| assoc.options[:dependent] == :destroy }
  end

  def destroy_dependent_associations_in_batches(exclude: [])
    dependent_associations_to_destroy.each do |association|
      next if exclude.include?(association.name)

      # rubocop:disable GitlabSecurity/PublicSend
      public_send(association.name).find_each(batch_size: DEPENDENT_ASSOCIATIONS_BATCH_SIZE, &:destroy)
    end
  end
end
