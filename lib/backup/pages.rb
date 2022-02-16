# frozen_string_literal: true

module Backup
  class Pages < Backup::Files
    # pages used to deploy tmp files to this path
    # if some of these files are still there, we don't need them in the backup
    LEGACY_PAGES_TMP_PATH = '@pages.tmp'

    attr_reader :progress

    def initialize(progress)
      @progress = progress

      super('pages', Gitlab.config.pages.path, excludes: [LEGACY_PAGES_TMP_PATH])
    end

    def human_name
      _('pages')
    end
  end
end
