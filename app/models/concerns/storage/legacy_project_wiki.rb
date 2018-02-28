module Storage
  module LegacyProjectWiki
    extend ActiveSupport::Concern

    def disk_path
      project.disk_path + '.wiki'
    end
  end
end
