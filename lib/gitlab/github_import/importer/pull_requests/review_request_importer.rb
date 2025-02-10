# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module PullRequests
        class ReviewRequestImporter
          include Gitlab::Utils::StrongMemoize
          include Gitlab::GithubImport::PushPlaceholderReferences

          def initialize(review_request, project, client)
            @review_request = review_request
            @project = project
            @user_finder = UserFinder.new(project, client)
            @mapper = Gitlab::GithubImport::ContributionsMapper.new(project)
          end

          def execute
            review_request.users.each do |user|
              user_id = user_finder.user_id_for(user, ghost: false)

              next unless user_id

              reviewer = MergeRequestReviewer.create!(
                merge_request_id: review_request.merge_request_id,
                user_id: user_id,
                state: MergeRequestReviewer.states['unreviewed'],
                created_at: Time.zone.now
              )

              next unless mapper.user_mapping_enabled?

              push_with_record(reviewer, :user_id, user&.id, mapper.user_mapper)
            rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique
            end
          end

          private

          attr_reader :review_request, :project, :user_finder, :mapper
        end
      end
    end
  end
end
