# frozen_string_literal: true

require 'backup/files'

module Backup
  class Pages < Files
    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('pages', Gitlab.config.pages.path, excludes: [::Projects::UpdatePagesService::TMP_EXTRACT_PATH])
    end
  end
end
