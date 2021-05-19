# frozen_string_literal: true

module Packages
  module Debian
    module Architecture
      extend ActiveSupport::Concern

      included do
        belongs_to :distribution, class_name: "Packages::Debian::#{container_type.capitalize}Distribution", inverse_of: :architectures
        # files must be destroyed by ruby code in order to properly remove carrierwave uploads
        has_many :files,
          class_name: "Packages::Debian::#{container_type.capitalize}ComponentFile",
          foreign_key: :architecture_id,
          inverse_of: :architecture,
          dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

        validates :distribution,
          presence: true

        validates :name,
          presence: true,
          length: { maximum: 255 },
          uniqueness: { scope: %i[distribution_id] },
          format: { with: Gitlab::Regex.debian_architecture_regex }

        scope :ordered_by_name, -> { order(:name) }
        scope :with_distribution, ->(distribution) { where(distribution: distribution) }
        scope :with_name, ->(name) { where(name: name) }
      end
    end
  end
end
