# frozen_string_literal: true

class Packages::Debian::GroupComponentFile < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::ComponentFile
end
