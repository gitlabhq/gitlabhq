# frozen_string_literal: true

module TimeTracking
  class TimelogCategory < ApplicationRecord
    include StripAttribute
    include CaseSensitivity

    self.table_name = "timelog_categories"

    belongs_to :namespace, foreign_key: 'namespace_id'

    has_many :timelogs

    strip_attributes! :name

    validates :namespace, presence: true
    validates :name, presence: true
    validates :name, uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    validates :name, length: { maximum: 255 }
    validates :description, length: { maximum: 1024 }
    validates :color, color: true, allow_blank: false, length: { maximum: 7 }
    validates :billing_rate,
      if: :billable?,
      presence: true,
      numericality: { greater_than: 0 }

    DEFAULT_COLOR = ::Gitlab::Color.of('#6699cc')

    attribute :color, ::Gitlab::Database::Type::Color.new, default: DEFAULT_COLOR

    def self.find_by_name(namespace_id, name)
      where(namespace: namespace_id)
        .iwhere(name: name)
    end
  end
end
