# frozen_string_literal: true

module Gitlab
  class NamespaceSanitizer
    def self.sanitize(namespace)
      namespace.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
    end
  end
end
