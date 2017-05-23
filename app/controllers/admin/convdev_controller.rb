class Admin::ConvdevController < Admin::ApplicationController
  def show
    @conversational_development_index_metric =
      ConversationalDevelopmentIndexMetric.order(:created_at).last
  end
end
