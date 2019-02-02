# frozen_string_literal: true

class UsersStarProject < ApplicationRecord
  include Sortable

  belongs_to :project, counter_cache: :star_count, touch: true
  belongs_to :user

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:project_id] }
  validates :project, presence: true

  alias_attribute :starred_since, :created_at

  scope :order_user_name_asc, -> { joins(:user).reorder('"users"."name" ASC') }
  scope :order_user_name_desc, -> { joins(:user).reorder('"users"."name" DESC') }
  scope :by_project, -> (project) { where(project_id: project.id) }
  scope :with_visible_profile, -> (user) { joins(:user).merge(User.with_visible_profile(user)) }

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
      joins(:user).merge(User.search(query))
    end
  end
end
