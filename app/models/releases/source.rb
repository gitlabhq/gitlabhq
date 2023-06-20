# frozen_string_literal: true

module Releases
  class Source
    include ActiveModel::Model

    attr_accessor :project, :tag_name, :format

    class << self
      def all(project, tag_name)
        Gitlab::Workhorse::ARCHIVE_FORMATS.map do |format|
          Releases::Source.new(project: project, tag_name: tag_name, format: format)
        end
      end
    end

    def url
      Gitlab::Routing
        .url_helpers
        .project_archive_url(project, id: File.join(tag_name, archive_prefix), format: format)
    end

    def hook_attrs
      {
        format: format,
        url: url
      }
    end

    private

    def archive_prefix
      "#{project.path}-#{tag_name.tr('/', '-')}"
    end
  end
end
