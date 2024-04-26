# frozen_string_literal: true

module Preloaders
  # This class preloads the `project`, `group`, and subscription associations for the given
  # labels, user, and project (if provided). A Label can be of type ProjectLabel or GroupLabel
  # and the preloader supports both.
  #
  # Usage:
  #   labels = Label.where(...)
  #   Preloaders::LabelsPreloader.new(labels, current_user, @project).preload_all
  #   labels.first.project # won't fire any query
  class LabelsPreloader
    attr_reader :labels, :user, :project

    def initialize(labels, user, project = nil)
      @labels = labels
      @user = user
      @project = project
    end

    def preload_all
      ActiveRecord::Associations::Preloader.new(
        records: project_labels,
        associations: { project: [:project_feature, { namespace: :route }] }
      ).call

      ActiveRecord::Associations::Preloader.new(
        records: group_labels,
        associations: { group: :route }
      ).call

      Preloaders::UserMaxAccessLevelInProjectsPreloader.new(project_labels.map(&:project), user).execute
      labels.each do |label|
        label.lazy_subscription(user)
        label.lazy_subscription(user, project) if project.present?
      end
    end

    private

    def group_labels
      @group_labels ||= labels.select { |l| l.is_a? GroupLabel }
    end

    def project_labels
      @project_labels ||= labels.select { |l| l.is_a? ProjectLabel }
    end
  end
end

Preloaders::LabelsPreloader.prepend_mod_with('Preloaders::LabelsPreloader')
