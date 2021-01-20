# frozen_string_literal: true

module Packages
  module Debian
    module Architecture
      extend ActiveSupport::Concern

      included do
        belongs_to :distribution, class_name: "Packages::Debian::#{container_type.capitalize}Distribution", inverse_of: :architectures

        validates :distribution,
          presence: true

        validates :name,
          presence: true,
          length: { maximum: 255 },
          uniqueness: { scope: %i[distribution_id] },
          format: { with: Gitlab::Regex.debian_architecture_regex }

        scope :with_distribution, ->(distribution) { where(distribution: distribution) }
        scope :with_name, ->(name) { where(name: name) }
      end
    end
  end
end
