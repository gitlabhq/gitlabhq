# frozen_string_literal: true

class Packages::Debian::ProjectComponent < ApplicationRecord
  def self.container_type
    :project
  end

  include Packages::Debian::Component
end
