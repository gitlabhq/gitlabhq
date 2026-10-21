# frozen_string_literal: true

module API
  module Entities
    class Compare < Grape::Entity
      expose :commit, using: ::API::Entities::Commit, documentation: { type: '::API::Entities::Commit' } do |compare, _|
        compare.commits.last
      end

      expose :commits, using: ::API::Entities::Commit,
        documentation: { type: '::API::Entities::Commit', is_array: true } do |compare, _|
        compare.commits
      end

      expose :diffs, using: ::API::Entities::Diff,
        documentation: { type: '::API::Entities::Diff', is_array: true } do |compare, _|
        diff_collection(compare).to_a
      end

      expose :compare_timeout, documentation: { type: 'Boolean' } do |compare, _|
        diff_collection(compare).overflow?
      end

      expose :same, as: :compare_same_ref, documentation: { type: 'Boolean' }

      expose :web_url,
        documentation: {
          type: 'String',
          example: "https://gitlab.example.com/gitlab/gitlab-foss/-/compare/main...feature"
        } do |compare, _|
        Gitlab::UrlBuilder.build(compare)
      end

      private

      # Compare#diffs builds a new collection on every call, and each one makes its own CommitDiff RPC.
      def diff_collection(compare)
        @diff_collection ||= compare.diffs.diffs
      end
    end
  end
end
