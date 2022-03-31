# frozen_string_literal: true

# Monkey patch of RDoc to prevent Ruby segfault due to
# stack buffer overflow Ruby bug -
# https://bugs.ruby-lang.org/issues/16376
#
# Safe to remove once GitLab upgrades to Ruby 3.0
# or once the fix is backported to 2.7.x and
# GitLab upgrades.
# https://gitlab.com/gitlab-org/gitlab/-/issues/351179
class RDoc::Markup::ToHtml
  def parseable?(_)
    false
  end
end

class RDoc::Markup::Verbatim
  def ruby?
    false
  end
end
