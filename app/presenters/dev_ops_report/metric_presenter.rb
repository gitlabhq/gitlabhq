# frozen_string_literal: true

module DevOpsReport
  class MetricPresenter < Gitlab::View::Presenter::Simple
    presents ::DevOpsReport::Metric, as: :metric

    delegate :created_at, to: :metric

    def cards
      [
        Card.new(
          metric: metric,
          title: 'Issues',
          description: 'created per active user',
          feature: 'issues',
          blog: 'https://www2.deloitte.com/content/dam/Deloitte/se/Documents/technology-media-telecommunications/deloitte-digital-collaboration.pdf'
        ),
        Card.new(
          metric: metric,
          title: 'Comments',
          description: 'created per active user',
          feature: 'notes',
          blog: 'http://conversationaldevelopment.com/why/'
        ),
        Card.new(
          metric: metric,
          title: 'Milestones',
          description: 'created per active user',
          feature: 'milestones',
          blog: 'http://conversationaldevelopment.com/shorten-cycle/',
          docs: help_page_path('user/project/milestones/_index.md')
        ),
        Card.new(
          metric: metric,
          title: 'Boards',
          description: 'created per active user',
          feature: 'boards',
          blog: 'http://jpattonassociates.com/user-story-mapping/',
          docs: help_page_path('user/project/issue_board.md')
        ),
        Card.new(
          metric: metric,
          title: 'Merge requests',
          description: 'per active user',
          feature: 'merge_requests',
          blog: 'https://8thlight.com/blog/uncle-bob/2013/02/01/The-Humble-Craftsman.html',
          docs: help_page_path('user/project/merge_requests/_index.md')
        ),
        Card.new(
          metric: metric,
          title: 'Pipelines',
          description: 'created per active user',
          feature: 'ci_pipelines',
          blog: 'https://martinfowler.com/bliki/ContinuousDelivery.html',
          docs: help_page_path('ci/_index.md')
        ),
        Card.new(
          metric: metric,
          title: 'Environments',
          description: 'created per active user',
          feature: 'environments',
          blog: promo_url(path: '/2016/08/26/ci-deployment-and-environments/'),
          docs: help_page_path('ci/environments/_index.md')
        ),
        Card.new(
          metric: metric,
          title: 'Deployments',
          description: 'created per active user',
          feature: 'deployments',
          blog: 'https://puppet.com/blog/continuous-delivery-vs-continuous-deployment-what-s-diff'
        ),
        Card.new(
          metric: metric,
          title: 'Monitoring',
          description: 'fraction of all projects',
          feature: 'projects_prometheus_active',
          blog: 'https://prometheus.io/docs/introduction/overview/'
        ),
        Card.new(
          metric: metric,
          title: 'Service Desk',
          description: 'issues created per active user',
          feature: 'service_desk_issues',
          blog: 'http://blogs.forrester.com/kate_leggett/17-01-30-top_trends_for_customer_service_in_2017_operations_become_smarter_and_more_strategic',
          docs: 'https://docs.gitlab.com/user/project/service_desk/'
        )
      ]
    end

    def idea_to_production_steps
      [
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Idea',
          features: %w[issues]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Issue',
          features: %w[issues notes]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Plan',
          features: %w[milestones boards]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Code',
          features: %w[merge_requests]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Commit',
          features: %w[merge_requests]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Test',
          features: %w[ci_pipelines]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Review',
          features: %w[ci_pipelines environments]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Staging',
          features: %w[environments deployments]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Production',
          features: %w[deployments]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Feedback',
          features: %w[projects_prometheus_active service_desk_issues]
        )
      ]
    end

    def average_percentage_score
      cards.sum(&:percentage_score) / cards.size.to_f
    end
  end
end
