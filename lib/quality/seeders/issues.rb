# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord
module Quality
  module Seeders
    class Issues
      DEFAULT_BACKFILL_WEEKS = 52
      DEFAULT_AVERAGE_ISSUES_PER_WEEK = 10

      attr_reader :project, :user

      def initialize(project:)
        @project = project
      end

      def seed(backfill_weeks: DEFAULT_BACKFILL_WEEKS, average_issues_per_week: DEFAULT_AVERAGE_ISSUES_PER_WEEK)
        created_at = backfill_weeks.to_i.weeks.ago
        team = project.team.users
        created_issues_count = 0

        loop do
          rand(average_issues_per_week * 2).times do
            params = {
              title: FFaker::Lorem.sentence(6),
              description: FFaker::Lorem.sentence,
              created_at: created_at + rand(6).days,
              state: %w[opened closed].sample,
              milestone: project.milestones.sample,
              assignee_ids: Array(team.pluck(:id).sample(3)),
              labels: labels.join(',')
            }
            params[:closed_at] = params[:created_at] + rand(35).days if params[:state] == 'closed'
            issue = ::Issues::CreateService.new(project: project, current_user: team.sample, params: params, spam_params: nil).execute

            if issue.persisted?
              created_issues_count += 1
              print '.' # rubocop:disable Rails/Output
            end
          end

          created_at += 1.week

          break if created_at > Time.now
        end

        created_issues_count
      end

      private

      def labels
        @labels_pool ||= project.labels.limit(rand(3)).pluck(:title).tap do |labels_array|
          labels_array.concat(project.group.labels.limit(rand(3)).pluck(:title)) if project.group
        end
      end
    end
  end
end
# rubocop:enable CodeReuse/ActiveRecord
