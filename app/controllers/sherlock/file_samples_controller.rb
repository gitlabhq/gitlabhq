module Sherlock
  class FileSamplesController < Sherlock::ApplicationController
    def show
      @file_sample = @transaction.find_file_sample(params[:id])
    end
  end
end
