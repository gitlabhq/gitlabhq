module Gitlab
  class PagesTransfer < ProjectTransfer
    def root_dir
      Gitlab.config.pages.path
    end
  end
end
