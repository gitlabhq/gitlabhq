module Sherlock
  class ApplicationController < ::ApplicationController
    before_action :find_transaction

    def find_transaction
      if params[:transaction_id]
        @transaction = Gitlab::Sherlock.collection.
          find_transaction(params[:transaction_id])
      end
    end
  end
end
