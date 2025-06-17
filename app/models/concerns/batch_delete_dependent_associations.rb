# frozen_string_literal: true

# Provides a way to delete_all in smaller batches, for cases where a large number of associations
# may be present on a model.
#
# This concern allows an ActiveRecord module to delete all its dependent
# associations in batches. The idea is borrowed from https://github.com/thisismydesign/batch_dependent_associations.
#
# The differences here with that gem:
#
# 1. We allow excluding certain associations.
module BatchDeleteDependentAssociations # rubocop:disable Gitlab/BoundedContexts -- generic code
  extend ActiveSupport::Concern

  DEPENDENT_ASSOCIATIONS_BATCH_SIZE = 1000

  def dependent_associations_to_delete
    self.class.reflect_on_all_associations(:has_many).select { |assoc| assoc.options[:dependent] == :delete_all }
  end

  def delete_dependent_associations_in_batches(exclude: [], batch_size: DEPENDENT_ASSOCIATIONS_BATCH_SIZE)
    dependent_associations_to_delete.each do |association|
      next if exclude.include?(association.name)

      loop do
        # rubocop:disable GitlabSecurity/PublicSend -- metaprogramming for modular concern
        delete_count = public_send(association.name).limit(batch_size).delete_all
        # rubocop:enable GitlabSecurity/PublicSend
        break if delete_count < batch_size
      end
    end
  end
end
