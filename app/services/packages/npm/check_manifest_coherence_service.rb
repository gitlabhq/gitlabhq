# frozen_string_literal: true

module Packages
  module Npm
    class CheckManifestCoherenceService
      MismatchError = Class.new(StandardError)

      delegate :npm_metadatum, to: :package, private: true
      delegate :package_json_scripts, to: :npm_metadatum, private: true, allow_nil: true

      def initialize(package, package_json_entry)
        @package = package
        @package_json_entry = package_json_entry
        @handler = SajHandler.new
      end

      def execute
        extract_manifest_data
        raise MismatchError, 'Package manifest is not coherent' unless coherent?

        ServiceResponse.success
      end

      private

      attr_reader :package, :package_json_entry, :handler

      def extract_manifest_data
        ::Oj.saj_parse(handler, package_json_entry)
      rescue SajHandler::ParsingDoneError
        # no-op
        # this simply signals that the handler has been stopped
        # and that's ok.
      end

      def coherent?
        handler.name == package.name &&
          handler.version == package.version &&
          handler.scripts == (package_json_scripts || {})
      end

      class SajHandler < ::Oj::Saj
        ParsingDoneError = Class.new(StandardError)

        attr_reader :name, :version, :scripts

        def initialize
          @in_scripts_block = false
          @scripts_processed = false

          @scripts = {}
          @name = nil
          @version = nil
        end

        def hash_start(key)
          return unless key == 'scripts'

          self.in_scripts_block = true
        end

        def hash_end(key)
          return unless key == 'scripts'

          self.in_scripts_block = false
          self.scripts_processed = true

          raise ParsingDoneError if complete?
        end

        def add_value(value, key)
          if in_scripts_block
            scripts[key] = value
          elsif key == 'name'
            self.name = value
          elsif key == 'version'
            self.version = value
          end

          raise ParsingDoneError if complete?
        end

        private

        attr_writer :name, :version
        attr_accessor :in_scripts_block, :scripts_processed

        def complete?
          scripts_processed && name && version
        end
      end
    end
  end
end
