# frozen_string_literal: true

module Serverless
  class AssociateDomainService
    PLACEHOLDER_HOSTNAME = 'example.com'

    def initialize(knative, pages_domain_id:, creator:)
      @knative = knative
      @pages_domain_id = pages_domain_id
      @creator = creator
    end

    def execute
      return if unchanged?

      knative.hostname ||= PLACEHOLDER_HOSTNAME

      knative.pages_domain = knative.find_available_domain(pages_domain_id)
      knative.serverless_domain_cluster.update(creator: creator) if knative.pages_domain
    end

    private

    attr_reader :knative, :pages_domain_id, :creator

    def unchanged?
      knative.pages_domain&.id == pages_domain_id
    end
  end
end
