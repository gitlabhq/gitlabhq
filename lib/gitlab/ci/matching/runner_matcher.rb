# frozen_string_literal: true

module Gitlab
  module Ci
    module Matching
      ###
      # This class is used to check if a build can be picked by a runner:
      #
      # runner = Ci::Runner.find(id)
      # build  = Ci::Build.find(id)
      # runner.runner_matcher.matches?(build.build_matcher)
      #
      # There are also class level methods to build matchers:
      #
      # `project.builds.build_matchers(project)` returns a distinct collection
      # of build matchers.
      # `Ci::Runner.runner_matchers` returns a distinct collection of runner matchers.
      #
      class RunnerMatcher
        ATTRIBUTES = %i[
          runner_ids
          runner_type
          public_projects_minutes_cost_factor
          private_projects_minutes_cost_factor
          run_untagged
          access_level
          tag_list
        ].freeze

        attr_reader(*ATTRIBUTES)

        def initialize(params)
          ATTRIBUTES.each do |attribute|
            instance_variable_set("@#{attribute}", params.fetch(attribute))
          end
        end

        def matches?(build_matcher)
          ensure_build_matcher_instance!(build_matcher)
          return false if ref_protected? && !build_matcher.protected?

          accepting_tags?(build_matcher)
        end

        def instance_type?
          runner_type.to_sym == :instance_type
        end

        private

        def ref_protected?
          access_level.to_sym == :ref_protected
        end

        def accepting_tags?(build_matcher)
          (run_untagged || build_matcher.has_tags?) && (build_matcher.tag_list - tag_list).empty?
        end

        def ensure_build_matcher_instance!(build_matcher)
          return if build_matcher.is_a?(Matching::BuildMatcher)

          raise ArgumentError, 'only Gitlab::Ci::Matching::BuildMatcher are allowed'
        end
      end
    end
  end
end

Gitlab::Ci::Matching::RunnerMatcher.prepend_mod_with('Gitlab::Ci::Matching::RunnerMatcher')
