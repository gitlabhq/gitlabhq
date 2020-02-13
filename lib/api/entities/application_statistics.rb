# frozen_string_literal: true

module API
  module Entities
    class ApplicationStatistics < Grape::Entity
      include ActionView::Helpers::NumberHelper
      include CountHelper

      expose :forks do |counts|
        approximate_fork_count_with_delimiters(counts)
      end

      expose :issues do |counts|
        approximate_count_with_delimiters(counts, ::Issue)
      end

      expose :merge_requests do |counts|
        approximate_count_with_delimiters(counts, ::MergeRequest)
      end

      expose :notes do |counts|
        approximate_count_with_delimiters(counts, ::Note)
      end

      expose :snippets do |counts|
        approximate_count_with_delimiters(counts, ::Snippet)
      end

      expose :ssh_keys do |counts|
        approximate_count_with_delimiters(counts, ::Key)
      end

      expose :milestones do |counts|
        approximate_count_with_delimiters(counts, ::Milestone)
      end

      expose :users do |counts|
        approximate_count_with_delimiters(counts, ::User)
      end

      expose :projects do |counts|
        approximate_count_with_delimiters(counts, ::Project)
      end

      expose :groups do |counts|
        approximate_count_with_delimiters(counts, ::Group)
      end

      expose :active_users do |_|
        number_with_delimiter(::User.active.count)
      end
    end
  end
end
