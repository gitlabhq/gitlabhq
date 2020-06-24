# frozen_string_literal: true

module Gitlab
  module WikiPages
    # Many common file systems have a limit of 255 bytes for file and
    # directory names, and while Git and GitLab both support paths exceeding
    # those limits, the presence of them makes it impossible for users on
    # those file systems to checkout a wiki repository locally.

    # To avoid this situation, we enforce these limits when editing pages
    # through the GitLab web interface and API:
    MAX_TITLE_BYTES = 245 # reserving 10 bytes for the file extension
    MAX_DIRECTORY_BYTES = 255

    # Limit the number of pages displayed in the wiki sidebar.
    MAX_SIDEBAR_PAGES = 15
  end
end
