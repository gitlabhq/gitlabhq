# frozen_string_literal: true

require 'wikicloth'
require 'wikicloth/extensions/lua'

# Adds patch to disable lua support to eliminate vulnerability to injection attack.
#
# The maintainers are not releasing new versions, so we need to patch it here.
#
# If they ever do release a version which contains a fix for this, then we can remove this file.
#
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/345892#note_751107320

# Guard to ensure we remember to delete this patch if they ever release a new version of wikicloth
# which disables Lua by default or otherwise eliminates all vulnerabilities mentioned in
# https://gitlab.com/gitlab-org/gitlab/-/issues/345892, including the possibility of an HTML/JS
# injection attack as mentioned in https://gitlab.com/gitlab-org/gitlab/-/issues/345892#note_751981608
unless Gem::Version.new(WikiCloth::VERSION) == Gem::Version.new('0.8.1')
  raise 'New version of WikiCloth detected, please either update the version for this check, ' \
    'or remove this patch if no longer needed'
end

module WikiCloth
  class LuaExtension < Extension
    protected

    def init_lua
      @options[:disable_lua] = true
    end
  end
end
