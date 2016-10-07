module Mattermost
  class BaseService < ::BaseService
    def execute
      # Implement in child
      raise NotImplementedError
    end

    private

    def resource_id
      match = params[:text].to_s.match(/\A(\$|#|!)?(?<id>\d+)\z/)

      match ? match[:id] : nil
    end


    def generate_response(resource)
      return respond_404 if resource.nil?
      return single_resource(resource) unless resource.respond_to?(:count)
      return no_search_results if resource.empty?

      if resource.count == 1
        single_resource(resource.first)
      else
        multiple_resources(resource)
      end
    end

    def respond_404
      {
        response_type: :ephemeral,
        text: "404 not found! GitLab couldn't find what your were looking for! :boom:",
      }
    end

    def no_search_results
      {
        response_type: :ephemeral,
        text: "### No search results for \"#{params[:text]}\". :disappointed:"
      }
    end

    def multiple_resources(resources)
      list = resources.map { |r| "#{r.to_reference} #{r.title}" }.join('\n\n')

      {
        response_type: :ephemeral,
        text: "### Search results for \"#{params[:text]}\"\n\n#{list}"
      }
    end
  end
end
