# frozen_string_literal: true

module Gitlab
  module Git
    # DeclaredLicense is the software license declared in a LICENSE or COPYING
    # file in the git repository.
    class DeclaredLicense
      # SPDX Identifier for the license
      attr_reader :key

      # Full name of the license
      attr_reader :name

      # Nickname of the license (optional, a shorter user-friendly name)
      attr_reader :nickname

      # Filename of the file containing license
      attr_accessor :path

      # URL that points to the LICENSE
      attr_reader :url

      def initialize(key: nil, name: nil, nickname: nil, url: nil, path: nil)
        @key = key
        @name = name
        @nickname = nickname
        @url = url
        @path = path
      end

      def ==(other)
        return unless other.is_a?(self.class)

        key == other.key
      end
    end
  end
end
