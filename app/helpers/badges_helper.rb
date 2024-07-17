# frozen_string_literal: true

module BadgesHelper
  # Creates a GitLab UI badge.
  #
  # Examples:
  #   # Plain text badge
  #   gl_badge_tag("foo")
  #
  #   # Danger variant
  #   gl_badge_tag("foo", variant: :danger)
  #
  #   # With icon
  #   gl_badge_tag("foo", icon: "question-o")
  #
  #   # Icon-only
  #   gl_badge_tag("foo", icon: "question-o", icon_only: true)
  #
  #   # Badge link
  #   gl_badge_tag("foo", nil, href: some_path)
  #
  #   # Custom classes
  #   gl_badge_tag("foo", nil, class: "foo-bar")
  #
  #   # Block content
  #   gl_badge_tag({ variant: :danger }, { class: "foo-bar" }) do
  #     "foo"
  #   end
  #
  # For accessibility, ensure that the given text or block is non-empty.
  #
  # See also https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-badge--default.
  def gl_badge_tag(*args, &block)
    # Merge the options and html_options hashes if both are present,
    # because the badge component wants a flat list of keyword args.
    args.compact!
    hashes, params = args.partition { |a| a.is_a? Hash }
    options_hash = hashes.reduce({}, :merge)

    if block
      render Pajamas::BadgeComponent.new(**options_hash), &block
    else
      render Pajamas::BadgeComponent.new(*params, **options_hash)
    end
  end
end
