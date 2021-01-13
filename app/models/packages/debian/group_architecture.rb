# frozen_string_literal: true

class Packages::Debian::GroupArchitecture < ApplicationRecord
  def self.container_type
    :group
  end

  include Packages::Debian::Architecture
end
