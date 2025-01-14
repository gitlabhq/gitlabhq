# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module DocumentationLinks
        # This cop encourages using helper to link to documentation
        # in string literals.
        #
        # @example
        #   # bad
        #   'See [the docs](https://docs.gitlab.com/ee/user/permissions#roles).'
        #   _('See [the docs](https://docs.gitlab.com/ee/user/permissions#roles).')
        #
        #   # good
        #   docs_link = link_to _('the docs'), help_page_url('user/permissions.md', anchor: 'roles')
        #   "See #{docs_link}."
        #   _('See %{docs_link}.').html_safe % { docs_link: docs_link.html_safe }
        class HardcodedUrl < RuboCop::Cop::Base
          include RangeHelp

          MSG = 'Use `#help_page_url` instead of directly including link. ' \
            'See https://docs.gitlab.com/ee/development/documentation/help#linking-to-help.'

          DOCS_URL_REGEXP = %r{https://docs.gitlab.com/ee/[\w#%./-]+}

          def on_str(node)
            match = DOCS_URL_REGEXP.match(node.source)
            return unless match

            add_offense(bad_range(node, match))
          end

          private

          def bad_range(node, match)
            url_begin_pos, url_end_pos = match.offset(0)
            begin_pos = node.loc.expression.begin_pos + url_begin_pos

            range_between(begin_pos, begin_pos + (url_end_pos - url_begin_pos))
          end
        end
      end
    end
  end
end
