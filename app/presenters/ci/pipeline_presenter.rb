module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    presents :pipeline

    def status_title
      if auto_canceled?
        "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      end
    end
  end
end
