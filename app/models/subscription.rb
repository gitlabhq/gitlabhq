# frozen_string_literal: true

class Subscription < ApplicationRecord
  include FromUnion
  include EachBatch

  belongs_to :user
  belongs_to :project
  belongs_to :subscribable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :user, :subscribable, presence: true

  validates :project_id, uniqueness: { scope: [:subscribable_id, :subscribable_type, :user_id] }
end
