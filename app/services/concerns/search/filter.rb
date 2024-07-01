# frozen_string_literal: true

module Search
  module Filter
    private

    def filters
      {
        state: params[:state],
        confidential: params[:confidential],
        include_archived: params[:include_archived],
        num_context_lines: params[:num_context_lines]&.to_i,
        hybrid_similarity: params[:hybrid_similarity]&.to_f
      }
    end
  end
end

Search::Filter.prepend_mod
