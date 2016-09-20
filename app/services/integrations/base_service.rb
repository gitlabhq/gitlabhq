module Integrations
  class BaseService < ::BaseService
    def execute
      resource =
        if resource_id
          find_resource
        else
          collection.search(params[:text]).limit(5)
        end

      generate_response(resource)
    end

    private

    def find_resource
      collection.find_by(iid: resource_id)
    end

    def title(resource)
      format("#{resource.title}")
    end

    def link(resource)
      raise NotImplementedError
    end

    def resource_id
      data = params[:text].to_s.match(/\A(\$|#|!)?(\d+)\z/)

      data ? data[2].to_i : nil
    end

    def collection
      klass.where(project: project)
    end

    def generate_response(resource)
      return respond_404 if resource.nil?
      return single_resource(resource) unless resource.respond_to?(:count)

      if resource.empty?
        no_search_results
      elsif resource.count == 1
        single_resource(resource.first)
      else
        multiple_resources(resource)
      end
    end

    def slack_format(message)
      Slack::Notifier::LinkFormatter.format(message)
    end

    def no_search_results
      {
        text: "No search results for \"#{params[:text]}\". :disappointed:",
        response_type: :ephemeral
      }
    end

    def single_resource(resource)
      {
        response_type: :in_channel,
        attachments: [ large_attachment(resource) ]
      }
    end

    def multiple_resources(resources)
      {
        response_type: :ephemeral,
        text: "Search results for \"#{params[:text]}\"",
        attachments: resources.map { |item| small_attachment(item) }
      }
    end

    def respond_404
      {
        text: "404 not found! Please make you use the right identifier. :boom:",
        response_type: :ephemeral
      }
    end

    def large_attachment(issuable)
      small_attachment(issuable).merge(fields: fields(issuable))
    end

    def small_attachment(issuable)
      {
        fallback: issuable.title,
        title: title(issuable),
        title_link: link(issuable),
        text: issuable.description || "", # Slack doesn't like null
      }
    end

    def fields(issuable)
      result = [
        {
          title: 'Author',
          value: issuable.author.name,
          short: true
        }
      ]

      if issuable.assignee
        result << {
          title: 'Assignee',
          value: issuable.assignee.name,
          short: true
        }
      end

      result
    end
  end
end
