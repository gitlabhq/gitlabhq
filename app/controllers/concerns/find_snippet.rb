# frozen_string_literal: true

module FindSnippet
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  private

  # rubocop:disable CodeReuse/ActiveRecord
  def snippet
    strong_memoize(:snippet) do
      snippet_klass.inc_relations_for_view.find_by(id: snippet_id)
    end
  end
  # rubocop:enable CodeReuse/ActiveRecord

  def snippet_klass
    raise NotImplementedError
  end

  def snippet_id
    params[:id]
  end
end
