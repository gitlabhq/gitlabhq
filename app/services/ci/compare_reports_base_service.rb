# frozen_string_literal: true

module Ci
  # TODO: when using this class with exposed artifacts we see that there are
  # 2 responsibilities:
  # 1. reactive caching interface (same in all cases)
  # 2. data generator (report comparison in most of the case but not always)
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  class CompareReportsBaseService < ::BaseService
    def execute(base_pipeline, head_pipeline)
      return parsing_payload(base_pipeline, head_pipeline) if base_pipeline&.running?

      base_report = get_report(base_pipeline)
      head_report = get_report(head_pipeline)

      return parsing_payload(base_pipeline, head_pipeline) if base_report == :parsing || head_report == :parsing

      comparer = build_comparer(base_report, head_report)

      {
        status: :parsed,
        key: key(base_pipeline, head_pipeline),
        data: serializer_class
          .new(**serializer_params)
          .represent(comparer).as_json
      }
    rescue Gitlab::Ci::Parsers::ParserError => e
      {
        status: :error,
        key: key(base_pipeline, head_pipeline),
        status_reason: e.message
      }
    end

    def latest?(base_pipeline, head_pipeline, data)
      data&.fetch(:key, nil) == key(base_pipeline, head_pipeline)
    end

    protected

    def parsing_payload(base_pipeline, head_pipeline)
      {
        status: :parsing,
        key: key(base_pipeline, head_pipeline)
      }
    end

    def build_comparer(base_report, head_report)
      comparer_class.new(base_report, head_report)
    end

    private

    def key(base_pipeline, head_pipeline)
      [
        base_pipeline&.id, base_pipeline&.updated_at,
        head_pipeline&.id, head_pipeline&.updated_at
      ]
    end

    def comparer_class
      raise NotImplementedError
    end

    def serializer_class
      raise NotImplementedError
    end

    def serializer_params
      { project: project, current_user: current_user }
    end

    def get_report(pipeline)
      raise NotImplementedError
    end
  end
end
