module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    presents :pipeline

    def auto_canceled?
      canceled? && auto_canceled_by_id?
    end

    def status_title
      "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}" if auto_canceled?
    end
  end
end
