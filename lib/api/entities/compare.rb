# frozen_string_literal: true

module API
  module Entities
    class Compare < Grape::Entity
      expose :commit, using: Entities::Commit do |compare, _|
        compare.commits.last
      end

      expose :commits, using: Entities::Commit do |compare, _|
        compare.commits
      end

      expose :diffs, using: Entities::Diff do |compare, _|
        compare.diffs.diffs.to_a
      end

      expose :compare_timeout do |compare, _|
        compare.diffs.diffs.overflow?
      end

      expose :same, as: :compare_same_ref
    end
  end
end
