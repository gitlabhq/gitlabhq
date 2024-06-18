# frozen_string_literal: true

class UsersStarProject < ApplicationRecord
  include Sortable

  belongs_to :project
  belongs_to :user

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:project_id] }
  validates :project, presence: true

  alias_attribute :starred_since, :created_at

  after_create :increment_project_star_count
  after_destroy :decrement_project_star_count

  scope :with_active_user, -> { joins(:user).merge(User.with_state(:active)) }
  scope :order_user_name_asc, -> { joins(:user).merge(User.order_name_asc) }
  scope :order_user_name_desc, -> { joins(:user).merge(User.order_name_desc) }
  scope :by_project, ->(project) { where(project_id: project.id) }
  scope :with_visible_profile, ->(user) { joins(:user).merge(User.with_visible_profile(user)) }
  scope :with_public_profile, -> { joins(:user).merge(User.with_public_profile) }
  scope :preload_users, -> { preload(:user) }

  class << self
    def sort_by_attribute(method)
      order_method = method || 'id_desc'

      case order_method.to_s
      when 'name_asc' then order_user_name_asc
      when 'name_desc' then order_user_name_desc
      else
        order_by(order_method)
      end
    end

    def search(query)
      joins(:user).merge(User.search(query, use_minimum_char_limit: false))
    end
  end

  private

  def increment_project_star_count
    Project.update_counters(project, star_count: 1) if user.active?
  end

  def decrement_project_star_count
    Project.update_counters(project, star_count: -1) if user.active?
  end
end
