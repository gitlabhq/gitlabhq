# frozen_string_literal: true

# == Referable concern
#
# Contains functionality related to making a model referable in Markdown, such
# as "#1", "!2", "~3", etc.
module Referable
  extend ActiveSupport::Concern

  # Returns the String necessary to reference this object in Markdown
  #
  # from - Referring parent object
  #
  # This should be overridden by the including class.
  #
  # Examples:
  #
  #   Issue.first.to_reference               # => "#1"
  #   Issue.last.to_reference(other_project) # => "cross-project#1"
  #
  # Returns a String
  def to_reference(_from = nil, full:)
    ''
  end

  # If this referable object can serve as the base for the
  # reference of child objects (e.g. projects are the base of
  # issues), but it is formatted differently, then you may wish
  # to override this method.
  def to_reference_base(from = nil, full:, absolute_path: false)
    to_reference(from, full: full)
  end

  def reference_link_text(from = nil)
    to_reference(from)
  end

  included do
    alias_method :non_referable_inspect, :inspect
    alias_method :inspect, :referable_inspect
  end

  def referable_inspect
    if respond_to?(:id)
      "#<#{self.class.name} id:#{id} #{to_reference(full: true)}>"
    else
      "#<#{self.class.name} #{to_reference(full: true)}>"
    end
  end

  class_methods do
    # The character that prefixes the actual reference identifier
    #
    # This should be overridden by the including class.
    #
    # Examples:
    #
    #   Issue.reference_prefix        # => '#'
    #   MergeRequest.reference_prefix # => '!'
    #
    # Returns a String
    def reference_prefix
      ''
    end

    # Regexp pattern used to match references to this object
    #
    # This must be overridden by the including class.
    #
    # Returns a Regexp
    def reference_pattern
      raise NotImplementedError, "#{self} does not implement #{__method__}"
    end

    def reference_valid?(reference)
      true
    end

    def link_reference_pattern
      raise NotImplementedError, "#{self} does not implement #{__method__}"
    end

    # Regex to match a fully qualified URL to a particular route and pattern
    # under a group or project context.
    #
    # Example use:  WikiPage.link_reference_pattern may be defined as follows:
    #
    #   def self.link_reference_pattern
    #     @link_reference_pattern ||= project_or_group_link_reference_pattern(
    #       'wikis',
    #       %r{(?<wiki_page>[\/\w-]+)}
    #     )
    #   end
    #
    # This produces a regex which matches URLs like:
    #
    # 'http://gdk.test:3000/flightjs/Flight/-/wikis/henlo-worl/yippee' (wiki_page: '/henlo-worl/yippee')
    # 'http://gdk.test:3000/groups/flightjs/-/wikis/home' (wiki_page: 'home')
    #
    # The regex also matches arbitrary trailing path components if the supplied
    # `pattern` does not consume everything, as well as query string and anchor
    # (fragment) components. See `link_reference_pattern_suffix` for details.
    def project_or_group_link_reference_pattern(route, pattern)
      %r{
        (?<url>
          #{Regexp.escape(Gitlab.config.gitlab.url)}
          \/(groups\/)?#{namespace_reference_pattern}
          (?:\/\-)?
          #{link_reference_pattern_suffix(route, pattern)}
        )
      }x
    end

    # Same as `project_or_group_link_reference_pattern`, except there's no
    # provision for 'groups/' and `Project.reference_pattern` is used instead
    # of `namespace_reference_pattern`; i.e. a fully-qualified project must
    # be specified.
    def compose_link_reference_pattern(route, pattern)
      %r{
        (?<url>
          #{Regexp.escape(Gitlab.config.gitlab.url)}
          \/#{Project.reference_pattern}
          (?:\/\-)?
          #{link_reference_pattern_suffix(route, pattern)}
        )
      }x
    end

    # Same as `project_or_group_link_reference_pattern`, except there's no
    # provision for a group or pattern at all before the '/-', which is
    # non-optional.
    #
    # Example use:  PersonalSnippet.link_reference_pattern may be defined as follows:
    #
    #   def self.link_reference_pattern
    #     @link_reference_pattern ||=
    #       compose_top_level_link_reference_pattern('snippets', /(?<snippet>\d+)/)
    #   end
    #
    # This produces a regex which matches URLs like:
    #
    # 'http://gdk.test:3000/-/snippets/2468'  (snippet: '2468')
    # 'http://gdk-oc.local:13000/-/snippets/2468/raw/main/socks'  (snippet: '2468', path: '/raw/main/socks')
    def compose_top_level_link_reference_pattern(route, pattern)
      %r{
        (?<url>
          #{Regexp.escape(Gitlab.config.gitlab.url)}
          \/\-
          #{link_reference_pattern_suffix(route, pattern)}
        )
      }x
    end

    private

    def link_reference_pattern_suffix(route, pattern)
      %r{
        \/#{route.is_a?(Regexp) ? route : Regexp.escape(route)}
        \/#{pattern}
        (?<path>
          (\/[a-z0-9_=-]+)*\/*
        )?
        (?<query>
          \?[a-z0-9_=-]+
          (&[a-z0-9_=-]+)*
        )?
        (?<anchor>\#[a-z0-9_-]+)?
      }x
    end
  end
end
