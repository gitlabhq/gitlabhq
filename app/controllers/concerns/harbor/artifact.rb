# frozen_string_literal: true

module Harbor
  module Artifact
    def index
      respond_to do |format|
        format.json do
          artifacts
        end
      end
    end

    private

    def query_params
      params.permit(:repository_id, :search, :sort, :page, :limit)
    end

    def query
      Gitlab::Harbor::Query.new(container.harbor_integration, query_params)
    end

    def artifacts
      unless query.valid?
        return render(
          json: { message: 'Invalid parameters', errors: query.errors },
          status: :unprocessable_entity
        )
      end

      artifacts_json = ::Integrations::HarborSerializers::ArtifactSerializer.new
                                        .with_pagination(request, response)
                                        .represent(query.artifacts)
      render json: artifacts_json
    end

    def container
      raise NotImplementedError
    end
  end
end
