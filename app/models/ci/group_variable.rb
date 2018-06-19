module Ci
  class GroupVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    include HasVariable
    include Presentable

    belongs_to :group, class_name: "::Group"

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      scope: :group_id,
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
  end
end
