# frozen_string_literal: true

module Search
  class PipeAbuseDetector
    def initialize(search_type, params)
      @search_type = search_type
      @params = params
    end

    def abusive?
      return false if params&.query_string.blank?
      return false unless search_type_requires_pipe_detection?

      abuse_detected?
    end

    private

    attr_reader :search_type, :params

    # Overridden in EE to exclude zoekt exact search mode
    def search_type_requires_pipe_detection?
      true
    end

    def abuse_detected?
      Gitlab::Search::AbuseDetection.new(params).abusive_pipes?
    end
  end
end
Search::PipeAbuseDetector.prepend_mod
