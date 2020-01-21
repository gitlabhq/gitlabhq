# frozen_string_literal: true

class ReviewAppSetupEntity < Grape::Entity
  include RequestAwareEntity

  expose :can_setup_review_app?, as: :can_setup_review_app

  expose :all_clusters_empty?, as: :all_clusters_empty, if: -> (_, _) { project.can_setup_review_app? } do |project|
    project.all_clusters_empty?
  end

  expose :review_snippet, if: -> (_, _) { project.can_setup_review_app? } do |_|
    YAML.safe_load(File.read(Rails.root.join('lib', 'gitlab', 'ci', 'snippets', 'review_app_default.yml'))).to_s
  end

  private

  def current_user
    request.current_user
  end

  def project
    object
  end
end
