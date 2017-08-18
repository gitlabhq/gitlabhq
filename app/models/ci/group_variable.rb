module Ci
  class GroupVariable < ActiveRecord::Base
    extend Ci::Model
    include HasVariable
    include Presentable

    belongs_to :group

    validates :key, uniqueness: { scope: :group_id }

    scope :unprotected, -> { where(protected: false) }
  end
end
