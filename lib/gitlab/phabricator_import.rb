# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    BaseError = Class.new(StandardError)

    def self.available?
      Feature.enabled?(:phabricator_import, default_enabled: :yaml) &&
        Gitlab::CurrentSettings.import_sources.include?('phabricator')
    end
  end
end
