module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    presents :pipeline

    def status_title
      "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}" if auto_canceled?
    end
  end
end
