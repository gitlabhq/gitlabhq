# frozen_string_literal: true

class Packages::Debian::ProjectArchitecture < ApplicationRecord
  def self.container_type
    :project
  end

  include Packages::Debian::Architecture
end
