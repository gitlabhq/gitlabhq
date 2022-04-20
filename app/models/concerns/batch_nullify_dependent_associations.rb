# frozen_string_literal: true

# Provides a way to execute nullify behaviour in batches
# to avoid query timeouts for really big tables
# Assumes that associations have `dependent: :nullify` statement
module BatchNullifyDependentAssociations
  extend ActiveSupport::Concern

  class_methods do
    def dependent_associations_to_nullify
      reflect_on_all_associations(:has_many).select { |assoc| assoc.options[:dependent] == :nullify }
    end
  end

  def nullify_dependent_associations_in_batches(exclude: [], batch_size: 100)
    self.class.dependent_associations_to_nullify.each do |association|
      next if association.name.in?(exclude)

      loop do
        # rubocop:disable GitlabSecurity/PublicSend
        update_count = public_send(association.name).limit(batch_size).update_all(association.foreign_key => nil)
        # rubocop:enable GitlabSecurity/PublicSend
        break if update_count < batch_size
      end
    end
  end
end
