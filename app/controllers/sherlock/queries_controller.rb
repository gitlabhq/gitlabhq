module Sherlock
  class QueriesController < Sherlock::ApplicationController
    def show
      @query = @transaction.find_query(params[:id])
    end
  end
end
