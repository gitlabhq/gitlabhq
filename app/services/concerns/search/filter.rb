# frozen_string_literal: true

module Search
  module Filter
    private

    def filters
      { state: params[:state], confidential: params[:confidential] }
    end
  end
end

Search::Filter.prepend_mod
