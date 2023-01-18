# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    BaseError = Class.new(StandardError)

    def self.available?
      Gitlab::CurrentSettings.import_sources.include?('phabricator')
    end
  end
end
