# frozen_string_literal: true

module Packages
  # This module requires a status column.
  # It also requires a class method `installable_statuses`. This should be
  # an array that defines which values of the status column are
  # considered as installable.
  module Installable
    extend ActiveSupport::Concern

    included do
      scope :with_status, ->(status) { where(status: status) }
      scope :installable, -> { with_status(installable_statuses) }
    end
  end
end
