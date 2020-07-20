# frozen_string_literal: true

class LearnGitlab
  PROJECT_NAME = 'Learn GitLab'.freeze
  BOARD_NAME = 'GitLab onboarding'.freeze
  LABEL_NAME = 'Novice'.freeze

  def initialize(current_user)
    @current_user = current_user
  end

  def available?
    project && board && label
  end

  def project
    @project ||= current_user.projects.find_by_name(PROJECT_NAME)
  end

  def board
    return unless project

    @board ||= project.boards.find_by_name(BOARD_NAME)
  end

  def label
    return unless project

    @label ||= project.labels.find_by_name(LABEL_NAME)
  end

  private

  attr_reader :current_user
end
