# WARNING changes in this file must be manually propagated to gitaly-ruby.
#
# https://gitlab.com/gitlab-org/gitaly/blob/master/ruby/lib/gitlab/gollum.rb

module Gollum
  GIT_ADAPTER = "rugged".freeze
end
require "gollum-lib"

module Gollum
  class Committer
    # Patch for UTF-8 path
    def method_missing(name, *args)
      index.send(name, *args)
    end
  end

  class Wiki
    def pages(treeish = nil, limit: nil)
      tree_list((treeish || @ref), limit: limit)
    end

    def tree_list(ref, limit: nil)
      if (sha = @access.ref_to_sha(ref))
        commit = @access.commit(sha)
        tree_map_for(sha).inject([]) do |list, entry|
          next list unless @page_class.valid_page_name?(entry.name)

          list << entry.page(self, commit)
          break list if limit && list.size >= limit

          list
        end
      else
        []
      end
    end
  end

  module Git
    class Git
      def tree_entry(commit, path)
        pathname = Pathname.new(path)
        tmp_entry = nil

        pathname.each_filename do |dir|
          tmp_entry = if tmp_entry.nil?
                        commit.tree[dir]
                      else
                        @repo.lookup(tmp_entry[:oid])[dir]
                      end

          return nil unless tmp_entry
        end
        tmp_entry
      end
    end
  end
end

Rails.application.configure do
  config.after_initialize do
    Gollum::Page.per_page = Kaminari.config.default_per_page
  end
end
