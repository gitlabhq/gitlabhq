module Gitlab
  module Git
    module Local
      module Repository
        def local_languages(ref)
          ref ||= rugged.head.target_id
          languages = Linguist::Repository.new(rugged, ref).languages
          total = languages.map(&:last).sum

          languages = languages.map do |language|
            name, share = language
            color = Linguist::Language[name].color || "##{Digest::SHA256.hexdigest(name)[0...6]}"
            {
              value: (share.to_f * 100 / total).round(2),
              label: name,
              color: color,
              highlight: color
            }
          end

          languages.sort do |x, y|
            y[:value] <=> x[:value]
          end
        end

        def local_log(options)
          actual_ref = options[:ref] || root_ref
          begin
            sha = sha_from_ref(actual_ref)
          rescue Rugged::OdbError, Rugged::InvalidError, Rugged::ReferenceError
            # Return an empty array if the ref wasn't found
            return []
          end

          if log_using_shell?(options)
            log_by_shell(sha, options)
          else
            log_by_walk(sha, options)
          end
        end
  
        def sha_from_ref(ref)
          rev_parse_target(ref).oid
        end
  
        # Return the object that +revspec+ points to.  If +revspec+ is an
        # annotated tag, then return the tag's target instead.
        def rev_parse_target(revspec)
          obj = rugged.rev_parse(revspec)
          Gitlab::Git::Ref.dereference_object(obj)
        end

        private

        def log_using_shell?(options)
          options[:path].present? ||
            options[:disable_walk] ||
            options[:skip_merges] ||
            options[:after] ||
            options[:before]
        end

        def log_by_walk(sha, options)
          walk_options = {
            show: sha,
            sort: Rugged::SORT_NONE,
            limit: options[:limit],
            offset: options[:offset]
          }
          Rugged::Walker.walk(rugged, walk_options).to_a
        end

        # Gitaly note: JV: although #log_by_shell shells out to Git I think the
        # complexity is such that we should migrate it as Ruby before trying to
        # do it in Go.
        def log_by_shell(sha, options)
          limit = options[:limit].to_i
          offset = options[:offset].to_i
          use_follow_flag = options[:follow] && options[:path].present?

          # We will perform the offset in Ruby because --follow doesn't play well with --skip.
          # See: https://gitlab.com/gitlab-org/gitlab-ce/issues/3574#note_3040520
          offset_in_ruby = use_follow_flag && options[:offset].present?
          limit += offset if offset_in_ruby

          cmd = %W[#{Gitlab.config.git.bin_path} --git-dir=#{path} log]
          cmd << "--max-count=#{limit}"
          cmd << '--format=%H'
          cmd << "--skip=#{offset}" unless offset_in_ruby
          cmd << '--follow' if use_follow_flag
          cmd << '--no-merges' if options[:skip_merges]
          cmd << "--after=#{options[:after].iso8601}" if options[:after]
          cmd << "--before=#{options[:before].iso8601}" if options[:before]
          cmd << sha

          # :path can be a string or an array of strings
          if options[:path].present?
            cmd << '--'
            cmd += Array(options[:path])
          end

          raw_output = IO.popen(cmd) { |io| io.read }
          lines = offset_in_ruby ? raw_output.lines.drop(offset) : raw_output.lines

          lines.map! { |c| Rugged::Commit.new(rugged, c.strip) }
        end
      end
    end
  end
end
