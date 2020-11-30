# frozen_string_literal: true

class GitlabDanger
  LOCAL_RULES ||= %w[
    changes_size
    documentation
    frozen_string
    duplicate_yarn_dependencies
    prettier
    eslint
    karma
    database
    commit_messages
    product_analytics
    utility_css
    pajamas
    pipeline
  ].freeze

  CI_ONLY_RULES ||= %w[
    metadata
    changelog
    specs
    roulette
    ce_ee_vue_templates
    sidekiq_queues
    specialization_labels
    ci_templates
  ].freeze

  MESSAGE_PREFIX = '==>'.freeze

  attr_reader :gitlab_danger_helper

  def initialize(gitlab_danger_helper)
    @gitlab_danger_helper = gitlab_danger_helper
  end

  def self.local_warning_message
    "#{MESSAGE_PREFIX} Only the following Danger rules can be run locally: #{LOCAL_RULES.join(', ')}"
  end

  def self.success_message
    "#{MESSAGE_PREFIX} No Danger rule violations!"
  end

  def rule_names
    ci? ? LOCAL_RULES | CI_ONLY_RULES : LOCAL_RULES
  end

  def html_link(str)
    self.ci? ? gitlab_danger_helper.html_link(str) : str
  end

  def ci?
    !gitlab_danger_helper.nil?
  end
end
