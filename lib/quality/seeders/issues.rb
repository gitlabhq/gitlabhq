# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord
module Quality
  module Seeders
    class Issues
      DEFAULT_BACKFILL_WEEKS = 52
      DEFAULT_AVERAGE_ISSUES_PER_WEEK = 20

      attr_reader :project, :user

      def initialize(project:)
        @project = project
      end

      def seed(backfill_weeks: DEFAULT_BACKFILL_WEEKS, average_issues_per_week: DEFAULT_AVERAGE_ISSUES_PER_WEEK)
        create_milestones!
        create_team_members!

        created_at = backfill_weeks.to_i.weeks.ago
        team = project.team.users
        created_issues_count = 0

        loop do
          rand(1..average_issues_per_week).times do
            params = {
              title: FFaker::Lorem.sentence(6),
              description: FFaker::Lorem.sentence,
              created_at: created_at + rand(6).days,
              state: %w[opened closed].sample,
              milestone_id: project.milestones.sample&.id,
              assignee_ids: Array(team.pluck(:id).sample(rand(3))),
              due_date: rand(10).days.from_now,
              labels: labels.join(',')
            }.merge(additional_params)

            params[:closed_at] = params[:created_at] + rand(35).days if params[:state] == 'closed'
            create_result = ::Issues::CreateService.new(container: project, current_user: team.sample, params: params, perform_spam_check: false).execute_without_rate_limiting

            if create_result.success?
              created_issues_count += 1
              print '.' # rubocop:disable Rails/Output
            end
          end

          created_at += 1.week

          break if created_at.future?
        end

        created_issues_count
      end

      private

      # Overriden on Quality::Seeders::Insights::Issues
      def additional_params
        {}
      end

      def create_team_members!
        3.times do |i|
          user = FactoryBot.create(
            :user,
            name: "I User#{i}",
            username: "i-user-#{i}-#{suffix}",
            email: "i-user-#{i}@#{suffix}.com"
          )

          # need owner access to allow changing Issue#created_at
          project.add_owner(user)
        end

        Sidekiq::Worker.skipping_transaction_check do
          AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute
        end

        # Refind object toreload ProjectTeam association which is memoized at Project model
        @project = Project.find(project.id)
      end

      def create_milestones!
        3.times do |i|
          params = {
            project: project,
            title: "Sprint #{i + suffix}",
            description: FFaker::Lorem.sentence,
            state: [:active, :closed].sample
          }

          FactoryBot.create(:milestone, **params)
        end
      end

      def suffix
        @suffix ||= Time.now.to_i
      end

      def labels
        @labels_pool ||= project.labels.limit(rand(3)).pluck(:title).tap do |labels_array|
          labels_array.concat(project.group.labels.limit(rand(3)).pluck(:title)) if project.group
        end
      end
    end
  end
end
# rubocop:enable CodeReuse/ActiveRecord
