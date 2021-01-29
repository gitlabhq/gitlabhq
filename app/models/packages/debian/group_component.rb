# frozen_string_literal: true

class Packages::Debian::GroupComponent < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::Component
end
