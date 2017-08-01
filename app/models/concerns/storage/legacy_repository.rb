module Storage
  module LegacyRepository
    extend ActiveSupport::Concern

    delegate :disk_path, to: :project
  end
end
