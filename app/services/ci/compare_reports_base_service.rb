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

      head_report = get_report(head_pipeline)

      # This guard runs before the base report is fetched. For most subclasses that
      # fetch reads and parses every artifact on the base pipeline and its children,
      # which a missing head report would always discard.
      #
      # We return :error rather than :parsing so the MR widget stops polling - the
      # pipeline may never arrive, and :parsing would cause an unbounded polling loop.
      # The key is included so the cache self-heals: when a pipeline finally appears
      # the key changes, latest? returns false, InvalidateReactiveCache fires, and the
      # value is recomputed.
      #
      # This ordering also means a nil head report takes precedence over a base report
      # that is still :parsing. That is intentional: a missing head report is terminal,
      # so waiting on the base would be the unbounded polling this guard prevents. No
      # subclass returns both today - only Vulnerabilities::CompareSecurityReportsService
      # returns :parsing, and its get_report never returns nil.
      return missing_head_report_payload(base_pipeline, head_pipeline) if head_report.nil?

      base_report = get_report(base_pipeline)

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

    def missing_head_report_payload(base_pipeline, head_pipeline)
      {
        status: :error,
        key: key(base_pipeline, head_pipeline),
        status_reason: _('This merge request does not have reports to compare.')
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
