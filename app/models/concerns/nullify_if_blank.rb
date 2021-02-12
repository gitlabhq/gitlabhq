# frozen_string_literal: true

# Helper that sets attributes to nil prior to validation if they
# are blank (are false, empty or contain only whitespace), to avoid
# unnecessarily persisting empty strings.
#
# Model usage:
#
#   class User < ApplicationRecord
#     include NullifyIfBlank
#
#     nullify_if_blank :name, :email
#   end
#
#
# Test usage:
#
#   RSpec.describe User do
#     it { is_expected.to nullify_if_blank(:name) }
#     it { is_expected.to nullify_if_blank(:email) }
#   end
#
module NullifyIfBlank
  extend ActiveSupport::Concern

  class_methods do
    def nullify_if_blank(*attributes)
      self.attributes_to_nullify += attributes
    end
  end

  included do
    class_attribute :attributes_to_nullify,
      instance_accessor: false,
      instance_predicate: false,
      default: Set.new

    before_validation :nullify_blank_attributes
  end

  private

  def nullify_blank_attributes
    self.class.attributes_to_nullify.each do |attribute|
      assign_attributes(attribute => nil) if read_attribute(attribute).blank?
    end
  end
end
