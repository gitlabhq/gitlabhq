# frozen_string_literal: true

module API
  module Entities
    class ApplicationStatistics < Grape::Entity
      include ActionView::Helpers::NumberHelper
      include CountHelper

      expose :forks,
        documentation: { type: 'Integer', example: 6, desc: 'Approximate number of repo forks' } do |counts|
        approximate_fork_count_with_delimiters(counts)
      end

      expose :issues,
        documentation: { type: 'Integer', example: 121, desc: 'Approximate number of issues' } do |counts|
        approximate_count_with_delimiters(counts, ::Issue)
      end

      expose :merge_requests,
        documentation: { type: 'Integer', example: 49, desc: 'Approximate number of merge requests' } do |counts|
        approximate_count_with_delimiters(counts, ::MergeRequest)
      end

      expose :notes,
        documentation: { type: 'Integer', example: 6, desc: 'Approximate number of notes' } do |counts|
        approximate_count_with_delimiters(counts, ::Note)
      end

      expose :snippets,
        documentation: { type: 'Integer', example: 4, desc: 'Approximate number of snippets' } do |counts|
        approximate_count_with_delimiters(counts, ::Snippet)
      end

      expose :ssh_keys,
        documentation: { type: 'Integer', example: 11, desc: 'Approximate number of SSH keys' } do |counts|
        approximate_count_with_delimiters(counts, ::Key)
      end

      expose :milestones,
        documentation: { type: 'Integer', example: 3, desc: 'Approximate number of milestones' } do |counts|
        approximate_count_with_delimiters(counts, ::Milestone)
      end

      expose :users, documentation: { type: 'Integer', example: 22, desc: 'Approximate number of users' } do |counts|
        approximate_count_with_delimiters(counts, ::User)
      end

      expose :projects,
        documentation: { type: 'Integer', example: 4, desc: 'Approximate number of projects' } do |counts|
        approximate_count_with_delimiters(counts, ::Project)
      end

      expose :groups,
        documentation: { type: 'Integer', example: 1, desc: 'Approximate number of projects' } do |counts|
        approximate_count_with_delimiters(counts, ::Group)
      end

      expose :active_users,
        documentation: { type: 'Integer', example: 21, desc: 'Number of active users' } do |_|
        number_with_delimiter(::User.active.count)
      end
    end
  end
end
