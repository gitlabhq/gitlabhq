module Mattermost
  class BaseService < ::BaseService
    def execute
      resource = if resource_id
                   find_resource
                 else
                   collection.search(params[:text]).limit(5)
                 end

      generate_response(resource)
    end

    private

    def resource_id
      match = params[:text].to_s.match(/\A(\$|#|!)?(?<id>\d+)\z/)

      match ? match[:id] : nil
    end

    def find_resource
      collection.find_by(iid: resource_id)
    end

    def generate_response(resource)
      return response_404 if resource.nil?
      return single_resource(resource) unless resource.respond_to?(:count)
      return no_results if resource.empty?

      if resource.count == 1
        single_resource(resource)
      else
        multiple_resources(resource)
      end
    end

    def respond_404
      {
        response_type: :ephemeral,
        text: "404 not found! Please make you use the right identifier. :boom:",
      }
    end

    def no_search_results
      {
        response_type: :ephemeral,
        text: "No search results for \"#{params[:text]}\". :disappointed:"
      }
    end

    def single_resource(resource)
      {
        response_type: :in_channel,
        text: %{### #{resource.to_reference} #{resource.title}

        #{resource.description.truncate(256)}
        }
      }
    end

    def multiple_resources(resources)
      list = resources.map { |r| "#{r.to_reference} #{r.title}" }.join('\n\n')

      {
        response_type: :ephemeral,
        text: <<-MD
        #### Search results for \"#{params[:text]}\"

        #{list}
        MD
      }
    end
  end
end
