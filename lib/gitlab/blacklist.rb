module Gitlab
  module Blacklist
    extend self

    def path
      %w(admin dashboard files groups help profile projects search public assets u s teams merge_requests issues users snippets services repository hooks notes)
    end
  end
end
