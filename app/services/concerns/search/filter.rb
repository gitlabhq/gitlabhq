# frozen_string_literal: true

module Search
  module Filter
    private

    def filters
      {
        state: params[:state],
        confidential: params[:confidential],
        include_archived: params[:include_archived],
        autocomplete: params[:autocomplete]
      }
    end
  end
end

Search::Filter.prepend_mod
