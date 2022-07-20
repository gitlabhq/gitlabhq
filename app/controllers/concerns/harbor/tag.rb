# frozen_string_literal: true

module Harbor
  module Tag
    def index
      respond_to do |format|
        format.json do
          tags
        end
      end
    end

    private

    def query_params
      params.permit(:repository_id, :artifact_id, :sort, :page, :limit)
    end

    def query
      Gitlab::Harbor::Query.new(container.harbor_integration, query_params)
    end

    def tags
      unless query.valid?
        return render(
          json: { message: 'Invalid parameters', errors: query.errors },
          status: :unprocessable_entity
        )
      end

      tags_json = ::Integrations::HarborSerializers::TagSerializer.new
                                  .with_pagination(request, response)
                                  .represent(query.tags)
      render json: tags_json
    end

    def container
      raise NotImplementedError
    end
  end
end
