# frozen_string_literal: true

class Packages::Debian::ProjectComponentFile < ApplicationRecord
  def self.container_type
    :project
  end

  include Packages::Debian::ComponentFile
end
