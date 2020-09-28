# frozen_string_literal: true

class SnippetInputActionCollection
  include Gitlab::Utils::StrongMemoize

  attr_reader :actions

  delegate :empty?, :any?, :[], to: :actions

  def initialize(actions = [], allowed_actions: nil)
    @actions = actions.map do |action|
      params = action.merge(allowed_actions: allowed_actions)

      SnippetInputAction.new(**params)
    end
  end

  def to_commit_actions
    strong_memoize(:commit_actions) do
      actions.map { |action| action.to_commit_action }
    end
  end

  def valid?
    strong_memoize(:valid) do
      actions.all?(&:valid?)
    end
  end
end
