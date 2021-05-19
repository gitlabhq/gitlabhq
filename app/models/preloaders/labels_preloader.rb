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
      preloader = ActiveRecord::Associations::Preloader.new

      preloader.preload(labels.select {|l| l.is_a? ProjectLabel }, { project: [:project_feature, namespace: :route] })
      preloader.preload(labels.select {|l| l.is_a? GroupLabel }, { group: :route })
      labels.each do |label|
        label.lazy_subscription(user)
        label.lazy_subscription(user, project) if project.present?
      end
    end
  end
end

Preloaders::LabelsPreloader.prepend_mod_with('Preloaders::LabelsPreloader')
