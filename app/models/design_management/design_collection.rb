# frozen_string_literal: true

module DesignManagement
  class DesignCollection
    attr_reader :issue

    delegate :designs, :project, to: :issue

    def initialize(issue)
      @issue = issue
    end

    def find_or_create_design!(filename:)
      designs.find { |design| design.filename == filename } ||
        designs.safe_find_or_create_by!(project: project, filename: filename)
    end

    def versions
      @versions ||= DesignManagement::Version.for_designs(designs)
    end

    def repository
      project.design_repository
    end

    def designs_by_filename(filenames)
      designs.current.where(filename: filenames)
    end
  end
end
