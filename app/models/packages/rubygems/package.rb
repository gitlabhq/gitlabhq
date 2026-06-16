# frozen_string_literal: true

module Packages
  module Rubygems
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :rubygems_metadatum, inverse_of: :package, class_name: 'Packages::Rubygems::Metadatum'

      validates :name, format: { with: Gitlab::Regex.package_name_regex }

      scope :installable_for_project, ->(project) { for_projects(project).installable.has_version }

      def sync_rubygems_spec_files
        ::Packages::Rubygems::CreateSpecFilesWorker.perform_async(project_id)
      end
    end
  end
end
