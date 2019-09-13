# frozen_string_literal: true

module Git
  class WikiPushService < ::BaseService
    def execute
      # This is used in EE
    end
  end
end

Git::WikiPushService.prepend_if_ee('EE::Git::WikiPushService')
