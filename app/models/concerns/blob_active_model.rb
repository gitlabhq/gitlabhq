# frozen_string_literal: true

# To be included in blob classes which are to be
# treated as ActiveModel.
#
# The blob class must respond_to `project`
module BlobActiveModel
  extend ActiveSupport::Concern

  class_methods do
    def declarative_policy_class
      'BlobPolicy'
    end
  end

  def to_ability_name
    'blob'
  end
end
