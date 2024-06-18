# frozen_string_literal: true

class SnippetInputAction
  include ActiveModel::Validations

  ACTIONS = %i[create update delete move].freeze

  ACTIONS.each do |action_const|
    define_method "#{action_const}_action?" do
      action == action_const
    end
  end

  attr_reader :action, :previous_path, :file_path, :content

  validates :action, inclusion: { in: ACTIONS, message: "%{value} is not a valid action" }
  validates :previous_path, presence: true, if: :move_action?
  validates :file_path, presence: true, if: ->(action) { action.update_action? || action.delete_action? }
  validates :content, presence: true, if: ->(action) { action.create_action? || action.update_action? }
  validate :ensure_same_file_path_and_previous_path, if: :update_action?
  validate :ensure_different_file_path_and_previous_path, if: :move_action?
  validate :ensure_allowed_action

  def initialize(action: nil, previous_path: nil, file_path: nil, content: nil, allowed_actions: nil)
    @action = action&.to_sym
    @previous_path = previous_path
    @file_path = file_path
    @content = content
    @allowed_actions = Array(allowed_actions).map(&:to_sym)
  end

  def to_commit_action
    {
      action: action,
      previous_path: build_previous_path,
      file_path: file_path,
      content: content
    }
  end

  private

  def build_previous_path
    return previous_path unless update_action?

    previous_path.presence || file_path
  end

  def ensure_same_file_path_and_previous_path
    return if previous_path.blank? || file_path.blank?
    return if previous_path == file_path

    errors.add(:file_path, "can't be different from the previous_path attribute")
  end

  def ensure_different_file_path_and_previous_path
    return if previous_path != file_path

    errors.add(:file_path, 'must be different from the previous_path attribute')
  end

  def ensure_allowed_action
    return if @allowed_actions.empty?

    unless @allowed_actions.include?(action)
      errors.add(:action, 'is not allowed')
    end
  end
end
