# frozen_string_literal: true

module DevOpsReport
  class MetricPresenter < Gitlab::View::Presenter::Simple
    delegate :created_at, to: :subject

    def cards
      [
        Card.new(
          metric: subject,
          title: 'Issues',
          description: 'created per active user',
          feature: 'issues',
          blog: 'https://www2.deloitte.com/content/dam/Deloitte/se/Documents/technology-media-telecommunications/deloitte-digital-collaboration.pdf'
        ),
        Card.new(
          metric: subject,
          title: 'Comments',
          description: 'created per active user',
          feature: 'notes',
          blog: 'http://conversationaldevelopment.com/why/'
        ),
        Card.new(
          metric: subject,
          title: 'Milestones',
          description: 'created per active user',
          feature: 'milestones',
          blog: 'http://conversationaldevelopment.com/shorten-cycle/',
          docs: help_page_path('user/project/milestones/index')
        ),
        Card.new(
          metric: subject,
          title: 'Boards',
          description: 'created per active user',
          feature: 'boards',
          blog: 'http://jpattonassociates.com/user-story-mapping/',
          docs: help_page_path('user/project/issue_board')
        ),
        Card.new(
          metric: subject,
          title: 'Merge requests',
          description: 'per active user',
          feature: 'merge_requests',
          blog: 'https://8thlight.com/blog/uncle-bob/2013/02/01/The-Humble-Craftsman.html',
          docs: help_page_path('user/project/merge_requests/index')
        ),
        Card.new(
          metric: subject,
          title: 'Pipelines',
          description: 'created per active user',
          feature: 'ci_pipelines',
          blog: 'https://martinfowler.com/bliki/ContinuousDelivery.html',
          docs: help_page_path('ci/index')
        ),
        Card.new(
          metric: subject,
          title: 'Environments',
          description: 'created per active user',
          feature: 'environments',
          blog: 'https://about.gitlab.com/2016/08/26/ci-deployment-and-environments/',
          docs: help_page_path('ci/environments')
        ),
        Card.new(
          metric: subject,
          title: 'Deployments',
          description: 'created per active user',
          feature: 'deployments',
          blog: 'https://puppet.com/blog/continuous-delivery-vs-continuous-deployment-what-s-diff'
        ),
        Card.new(
          metric: subject,
          title: 'Monitoring',
          description: 'fraction of all projects',
          feature: 'projects_prometheus_active',
          blog: 'https://prometheus.io/docs/introduction/overview/',
          docs: help_page_path('user/project/integrations/prometheus')
        ),
        Card.new(
          metric: subject,
          title: 'Service Desk',
          description: 'issues created per active user',
          feature: 'service_desk_issues',
          blog: 'http://blogs.forrester.com/kate_leggett/17-01-30-top_trends_for_customer_service_in_2017_operations_become_smarter_and_more_strategic',
          docs: 'https://docs.gitlab.com/ee/user/project/service_desk.html'
        )
      ]
    end

    def idea_to_production_steps
      [
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Idea',
          features: %w(issues)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Issue',
          features: %w(issues notes)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Plan',
          features: %w(milestones boards)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Code',
          features: %w(merge_requests)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Commit',
          features: %w(merge_requests)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Test',
          features: %w(ci_pipelines)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Review',
          features: %w(ci_pipelines environments)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Staging',
          features: %w(environments deployments)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Production',
          features: %w(deployments)
        ),
        IdeaToProductionStep.new(
          metric: subject,
          title: 'Feedback',
          features: %w(projects_prometheus_active service_desk_issues)
        )
      ]
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def average_percentage_score
      cards.sum(&:percentage_score) / cards.size.to_f
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
