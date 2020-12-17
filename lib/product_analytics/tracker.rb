# frozen_string_literal: true

module ProductAnalytics
  class Tracker
    # The file is located in the /public directory
    URL = Gitlab.config.gitlab.url + '/-/sp.js'

    # The collector URL minus protocol and /i
    COLLECTOR_URL = Gitlab.config.gitlab.url.sub(/\Ahttps?\:\/\//, '') + '/-/collector'
  end
end
