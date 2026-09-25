# frozen_string_literal: true

require_relative '../../../docs_anchor_helpers'

module RuboCop
  module Cop
    module Gitlab
      module DocumentationLinks
        # This cop encourages using helper to link to documentation
        # in string literals.
        #
        # @example
        #   # bad
        #   'See [the docs](https://docs.gitlab.com/user/permissions/#roles).'
        #   _('See [the docs](https://docs.gitlab.com/user/permissions/#roles).')
        #
        #   # good
        #   docs_link = link_to _('the docs'), help_page_url('user/permissions.md', anchor: 'roles')
        #   "See #{docs_link}."
        #   _('See %{docs_link}.').html_safe % { docs_link: docs_link.html_safe }
        #
        #   # also good (a Grape API description, resolved against doc/ instead)
        #   optional :with_custom_attributes, type: Boolean,
        #     desc: 'If `true`, includes [custom attributes](https://docs.gitlab.com/api/custom_attributes/).'
        #
        #   # bad (a Grape API description naming a page or an anchor that does not exist)
        #   optional :with_custom_attributes, type: Boolean,
        #     desc: 'If `true`, includes [custom attributes](https://docs.gitlab.com/api/moved_away/).'
        class HardcodedUrl < RuboCop::Cop::Base
          include RangeHelp
          include DocsAnchorHelpers

          MSG = 'Use `#help_page_url` instead of directly including link. ' \
            'See https://docs.gitlab.com/development/documentation/help/#linking-to-help.'

          MSG_FILE_NOT_FOUND = 'This documentation page does not exist: `%{file_path}`. An API ' \
            'description can link to docs.gitlab.com, but the page must exist.'

          # Excludes docs.gitlab.com/{runner,omnibus,charts}/... because those docs live in
          # separate repositories and can never be linked via `#help_page_url`.
          DOCS_URL_REGEXP = %r{https://docs.gitlab.com/(?:ee/)?(?!runner/|omnibus/|charts/)[\w#%./-]+}

          # A sentence's own punctuation is not part of the URL, and the regexp above cannot tell
          # the difference.
          TRAILING_PUNCTUATION = /[.,;:]+\z/

          def on_str(node)
            match = DOCS_URL_REGEXP.match(node.source)
            return unless match

            return check_api_description(node, match) if within_api_description?(node)

            add_offense(bad_range(node, match))
          end

          private

          # Grape `desc:` and `detail` strings are compiled into
          # doc/api/openapi/openapi_v3.yaml and published for readers who are not on the instance
          # that generated them, so `#help_page_url`, which builds an instance-rooted `/help` URL,
          # cannot express these links. They stay absolute and are resolved against doc/ instead,
          # so a page that moves or a heading that is renamed is still caught.
          # @!method api_description?(node)
          def_node_matcher :api_description?, <<~PATTERN
            {
              (pair (sym {:desc :detail}) _)
              (send nil? {:desc :detail} ...)
            }
          PATTERN

          # A `\`-continued literal parses as a `dstr` holding one `str` per line, and the
          # offence is reported on the line the URL sits on, so the `desc:` is further up.
          def within_api_description?(node)
            ancestor = node.parent
            ancestor = ancestor.parent while ancestor&.type?(:str, :dstr)

            !ancestor.nil? && api_description?(ancestor)
          end

          def check_api_description(node, match)
            url = match[0].sub(TRAILING_PUNCTUATION, '')
            slug = url[%r{docs\.gitlab\.com/(?:ee/)?([^#]*)}, 1].to_s.delete_suffix('/')
            return if slug.empty?

            file = docs_file_candidates(slug).find { |path| docs_file_exists?(path) }

            if file.nil?
              add_offense(bad_range(node, match),
                message: format(MSG_FILE_NOT_FOUND, file_path: docs_file_candidates(slug).first))
              return
            end

            anchor = url[/#(.+)\z/, 1]
            return if anchor_exists_in_markdown?(anchor, file)

            add_offense(bad_range(node, match),
              message: format(MSG_ANCHOR_NOT_FOUND, anchor: anchor, file_path: file))
          end

          # doc/a/b.md and doc/a/b/_index.md both publish as /a/b/ on docs.gitlab.com.
          def docs_file_candidates(slug)
            ["doc/#{slug}.md", "doc/#{slug}/_index.md"]
          end

          def bad_range(node, match)
            url_begin_pos, url_end_pos = match.offset(0)
            begin_pos = node.source_range.begin_pos + url_begin_pos

            range_between(begin_pos, begin_pos + (url_end_pos - url_begin_pos))
          end
        end
      end
    end
  end
end
