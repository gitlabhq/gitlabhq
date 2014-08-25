module Projects
  class TransferWiki < Projects::Base
    include Gitlab::ShellAdapter

    def perform
      # Move wiki repo also if present
      if project.wiki_enabled?
        gitlab_shell.mv_repository("#{context[:old_path]}.wiki",
                                   "#{context[:new_path]}.wiki")
      end
    end

    def rollback
      # Move wiki repo also if present
      if project.wiki_enabled?
        gitlab_shell.mv_repository("#{context[:new_path]}.wiki",
                                   "#{context[:old_path]}.wiki")
      end
    end
  end
end
