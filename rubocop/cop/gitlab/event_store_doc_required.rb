# frozen_string_literal: true

require 'digest/sha2'
require 'yaml'
require_relative '../../../tooling/docs/event_nodoc'

module RuboCop
  module Cop
    module Gitlab
      # Ensures every EventStore event class has a documentation file, and that
      # the documentation correctly reflects whether the event lives under
      # `ee/app/events/` (via `ee_only: true`) or `app/events/` (no `ee_only`).
      #
      # @example
      #   # bad - data/events/ci/pipeline_created_event.yml is missing
      #   module Ci
      #     class PipelineCreatedEvent < Gitlab::EventStore::Event; end
      #   end
      #
      #   # good - data/events/ci/pipeline_created_event.yml exists:
      #   # event: Ci::PipelineCreatedEvent
      #   # description: Published when a CI pipeline is created.
      #   # feature_category: continuous_integration
      class EventStoreDocRequired < RuboCop::Cop::Base
        MSG_MISSING = <<~MSG
          Add event documentation at `%<doc_path>s`.

          Option 1 — Auto-generate (requires glab with Duo CLI):
            scripts/generate_event_doc %<source_path>s
            (Setup: https://docs.gitlab.com/ee/user/gitlab_duo_cli/)

          Option 2 — Manually:
            cp data/events/templates/example.yml %<doc_path>s
            # fill in the fields, then:
            bin/rake gitlab:docs:compile_events
        MSG

        MSG_EE_ONLY_MISSING = <<~MSG
          Event class is under `ee/app/events/` but `%<doc_path>s` does not declare `ee_only: true`.
          Add `ee_only: true` to the YAML.
        MSG

        MSG_EE_ONLY_UNEXPECTED = <<~MSG
          Event class is under `app/events/` but `%<doc_path>s` declares `ee_only: true`.
          Remove `ee_only: true` from the YAML, or move the class under `ee/app/events/`.
        MSG

        def on_class(node)
          return unless in_events_dir?
          return if Docs::EventNodoc.excluded?(source_path, gitlab_root)

          doc_path = corresponding_doc_path

          unless File.exist?(doc_path)
            add_offense(
              node.loc.name,
              message: format(
                MSG_MISSING,
                doc_path: relative_doc_path(doc_path),
                source_path: relative_source_path
              )
            )
            return
          end

          check_ee_only_consistency(node, doc_path)
        end

        def external_dependency_checksum
          @external_dependency_checksum ||= begin
            root = File.expand_path('../../..', __dir__)
            digest = Digest::SHA256.new
            Dir.glob(File.join(root, 'data/events/**/*.yml')).each do |path|
              digest.update(path).file(path)
            end
            nodoc = File.join(root, Docs::EventNodoc::NODOC_FILENAME)
            digest.file(nodoc) if File.exist?(nodoc)
            digest.hexdigest
          end
        end

        private

        def check_ee_only_consistency(node, doc_path)
          declared_ee_only = ee_only_in_doc?(doc_path)

          if source_in_ee? && !declared_ee_only
            add_offense(
              node.loc.name,
              message: format(MSG_EE_ONLY_MISSING, doc_path: relative_doc_path(doc_path))
            )
          elsif !source_in_ee? && declared_ee_only
            add_offense(
              node.loc.name,
              message: format(MSG_EE_ONLY_UNEXPECTED, doc_path: relative_doc_path(doc_path))
            )
          end
        end

        def ee_only_in_doc?(doc_path)
          YAML.safe_load_file(doc_path)['ee_only'] == true
        rescue Psych::Exception
          false
        end

        def in_events_dir?
          source_path.include?('/app/events/')
        end

        def source_in_ee?
          source_path.include?('/ee/app/events/')
        end

        def corresponding_doc_path
          relative = source_path.sub(%r{^.+/app/events/}, '').sub(/\.rb$/, '.yml')
          File.join(gitlab_root, 'data/events', relative)
        end

        def relative_doc_path(absolute_path)
          absolute_path.delete_prefix("#{gitlab_root}/")
        end

        def relative_source_path
          source_path.delete_prefix("#{gitlab_root}/")
        end

        def source_path
          @source_path ||= processed_source.path.to_s
        end

        def gitlab_root
          @gitlab_root ||= Pathname.new(source_path).expand_path.ascend.find do |p|
            p.join('Gemfile').exist?
          end.to_s
        end
      end
    end
  end
end
