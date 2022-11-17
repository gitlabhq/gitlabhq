# frozen_string_literal: true

module API
  module Entities
    class Compare < Grape::Entity
      expose :commit, using: Entities::Commit do |compare, _|
        compare.commits.last
      end

      expose :commits, documentation: { is_array: true }, using: Entities::Commit do |compare, _|
        compare.commits
      end

      expose :diffs, documentation: { is_array: true }, using: Entities::Diff do |compare, _|
        compare.diffs.diffs.to_a
      end

      expose :compare_timeout, documentation: { type: 'boolean' } do |compare, _|
        compare.diffs.diffs.overflow?
      end

      expose :same, as: :compare_same_ref, documentation: { type: 'boolean' }

      expose :web_url,
        documentation: {
          example: "https://gitlab.example.com/gitlab/gitlab-foss/-/compare/main...feature"
        } do |compare, _|
        Gitlab::UrlBuilder.build(compare)
      end
    end
  end
end
