module Ci
  class PipelineStatusBadgePresenter < Gitlab::View::Presenter::Delegated
    presents :pipeline

    def auto_canceled?
      canceled? && auto_canceled_by_id?
    end

    def status_title
      "Pipeline is redundant and is auto-canceled by Pipeline ##{pipeline.auto_canceled_by_id}" if auto_canceled?
    end
  end
end
