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

    # Remove if https://github.com/gollum/gollum-lib/pull/292 has been merged
    def update_page(page, name, format, data, commit = {})
      name = name ? ::File.basename(name) : page.name
      format ||= page.format
      dir      = ::File.dirname(page.path)
      dir      = '' if dir == '.'
      filename = (rename = page.name != name) ? Gollum::Page.cname(name) : page.filename_stripped

      multi_commit = !!commit[:committer]
      committer    = multi_commit ? commit[:committer] : Committer.new(self, commit)

      if !rename && page.format == format
        committer.add(page.path, normalize(data))
      else
        committer.delete(page.path)
        committer.add_to_index(dir, filename, format, data)
      end

      committer.after_commit do |index, _sha|
        @access.refresh
        index.update_working_dir(dir, page.filename_stripped, page.format)
        index.update_working_dir(dir, filename, format)
      end

      multi_commit ? committer : committer.commit
    end

    # Remove if https://github.com/gollum/gollum-lib/pull/292 has been merged
    def rename_page(page, rename, commit = {})
      return false if page.nil?
      return false if rename.nil? || rename.empty?

      (target_dir, target_name) = ::File.split(rename)
      (source_dir, source_name) = ::File.split(page.path)
      source_name               = page.filename_stripped

      # File.split gives us relative paths with ".", commiter.add_to_index doesn't like that.
      target_dir                = '' if target_dir == '.'
      source_dir                = '' if source_dir == '.'
      target_dir                = target_dir.gsub(/^\//, '') # rubocop:disable Style/RegexpLiteral

      # if the rename is a NOOP, abort
      if source_dir == target_dir && source_name == target_name
        return false
      end

      multi_commit = !!commit[:committer]
      committer    = multi_commit ? commit[:committer] : Committer.new(self, commit)

      # This piece only works for multi_commit
      # If we are in a commit batch and one of the previous operations
      # has updated the page, any information we ask to the page can be outdated.
      # Therefore, we should ask first to the current committer tree to see if
      # there is any updated change.
      raw_data = raw_data_in_committer(committer, source_dir, page.filename) ||
        raw_data_in_committer(committer, source_dir, "#{target_name}.#{Page.format_to_ext(page.format)}") ||
        page.raw_data

      committer.delete(page.path)
      committer.add_to_index(target_dir, target_name, page.format, raw_data)

      committer.after_commit do |index, _sha|
        @access.refresh
        index.update_working_dir(source_dir, source_name, page.format)
        index.update_working_dir(target_dir, target_name, page.format)
      end

      multi_commit ? committer : committer.commit
    end

    # Remove if https://github.com/gollum/gollum-lib/pull/292 has been merged
    def raw_data_in_committer(committer, dir, filename)
      data = nil

      [*dir.split(::File::SEPARATOR), filename].each do |key|
        data = data ? data[key] : committer.tree[key]
        break unless data
      end

      data
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
