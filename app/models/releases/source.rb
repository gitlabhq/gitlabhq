# frozen_string_literal: true

module Releases
  class Source
    include ActiveModel::Model

    attr_accessor :project, :tag_name, :format

    FORMATS = %w(zip tar.gz tar.bz2 tar).freeze

    class << self
      def all(project, tag_name)
        Releases::Source::FORMATS.map do |format|
          Releases::Source.new(project: project,
                               tag_name: tag_name,
                               format: format)
        end
      end
    end

    def url
      Gitlab::Routing
        .url_helpers
        .project_archive_url(project,
                             id: File.join(tag_name, archive_prefix),
                             format: format)
    end

    private

    def archive_prefix
      "#{project.path}-#{tag_name.tr('/', '-')}"
    end
  end
end
