# frozen_string_literal: true

module Harbor
  module Repository
    def index
      respond_to do |format|
        format.html
        format.json do
          repositories
        end
      end
    end

    # The show action renders index to allow frontend routing to work on page refresh
    def show
      render :index
    end

    private

    def query_params
      params.permit(:search, :sort, :page, :limit)
    end

    def query
      Gitlab::Harbor::Query.new(container.harbor_integration, query_params)
    end

    def repositories
      unless query.valid?
        return render(
          json: { message: 'Invalid parameters', errors: query.errors },
          status: :unprocessable_entity
        )
      end

      repositories_json = ::Integrations::HarborSerializers::RepositorySerializer.new
                                        .with_pagination(request, response)
                                        .represent(
                                          query.repositories,
                                          url: container.harbor_integration.url,
                                          project_name: container.harbor_integration.project_name
                                        )
      render json: repositories_json
    end

    def container
      raise NotImplementedError
    end
  end
end
