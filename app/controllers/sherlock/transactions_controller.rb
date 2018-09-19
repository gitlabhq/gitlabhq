module Sherlock
  class TransactionsController < Sherlock::ApplicationController
    def index
      @transactions = Gitlab::Sherlock.collection.newest_first
    end

    def show
      @transaction = Gitlab::Sherlock.collection.find_transaction(params[:id])

      render_404 unless @transaction
    end

    def destroy_all
      Gitlab::Sherlock.collection.clear

      redirect_to :back, status: :found
    end
  end
end
