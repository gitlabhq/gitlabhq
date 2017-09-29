module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    prepend ::EE::Ci::PipelinePresenter

    presents :pipeline

    def status_title
      if auto_canceled?
        "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      end
    end
  end
end
