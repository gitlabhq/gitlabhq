# frozen_string_literal: true

module Ml
  class CandidatesCsvPresenter
    CANDIDATE_ASSOCIATIONS = [:latest_metrics, :params, :experiment].freeze
    # This file size limit is mainly to avoid the generation to hog resources from the server. The value is arbitrary
    # can be update once we have better insight into usage.
    TARGET_FILESIZE = 2.megabytes

    def initialize(candidates)
      @candidates = candidates
    end

    def present
      CsvBuilder.new(@candidates, headers, CANDIDATE_ASSOCIATIONS).render(TARGET_FILESIZE)
    end

    private

    def headers
      metric_names = columns_names(&:metrics)
      param_names = columns_names(&:params)

      candidate_to_metrics = @candidates.to_h do |candidate|
        [candidate.id, candidate.latest_metrics.to_h { |m| [m.name, m.value] }]
      end

      candidate_to_params = @candidates.to_h do |candidate|
        [candidate.id, candidate.params.to_h { |m| [m.name, m.value] }]
      end

      {
        project_id: 'project_id',
        experiment_iid: ->(c) { c.experiment.iid },
        candidate_iid: 'internal_id',
        name: 'name',
        external_id: 'eid',
        start_time: 'start_time',
        end_time: 'end_time',
        **param_names.index_with { |name| ->(c) { candidate_to_params.dig(c.id, name) } },
        **metric_names.index_with { |name| ->(c) { candidate_to_metrics.dig(c.id, name) } }
      }
    end

    def columns_names(&selector)
      @candidates.flat_map(&selector).map(&:name).uniq
    end
  end
end
