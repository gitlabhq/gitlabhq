# frozen_string_literal: true

require 'pact/consumer'

module ArtifactRegistry
  module Fixtures
    module Repositories
      # Pact interaction definition for GET /api/v1/:slug/repositories.
      #
      # Encapsulates the provider state, request shape, and expected response
      # so that index_spec.rb stays focused on orchestration only.
      module Index
        PROVIDER_STATE  = 'a namespace with repositories exists'
        UPON_RECEIVING  = 'a request for a list of artifact registry repositories'

        REQUEST = {
          method: :get,
          path: '/api/v1/my-namespace/repositories',
          query: 'limit=20',
          headers: { 'Accept' => 'application/json' }
        }.freeze

        RESPONSE = {
          status: 200,
          body: Pact.each_like(
            id: Pact::SomethingLike.new('dddddddd-dddd-dddd-dddd-dddddddddddd'),
            name: Pact::SomethingLike.new('my-maven-repo'),
            format: Pact::Term.new(generate: 'maven', matcher: /^(docker|oci|maven|npm)$/),
            kind: Pact::Term.new(generate: 'hosted', matcher: /^(hosted|virtual|remote)$/),
            visibility: Pact::Term.new(generate: 'private', matcher: /^(public|private|internal)$/),
            description: Pact::SomethingLike.new('A hosted Maven repository'),
            artifacts_count: Pact::SomethingLike.new(0),
            downloads_count: Pact::SomethingLike.new(0),
            size_bytes: Pact::SomethingLike.new(0),
            created_at: Pact::Term.new(
              generate: '2024-01-01T00:00:00Z',
              matcher: /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
            ),
            # null for freshly created repositories that have never been updated
            # or created/updated by a specific user (per S17 management API spec).
            # Non-null cases should be covered in separate interactions.
            # https://gitlab.com/gitlab-org/ops/artifact-registry/-/blob/main/docs/specs/S17-rest-management-api.md
            last_updated_at: nil,
            created_by: nil,
            updated_by: nil
          )
        }.freeze
      end
    end
  end
end
