# frozen_string_literal: true

module Organizations
  module Release
    # A registered organization flag: one of the Organizations team's feature
    # flags and the stage it currently sits at. Built from
    # config/organizations_release.yml by the Registry.
    Flag = Struct.new(:name, :description, :stage, keyword_init: true)
  end
end
