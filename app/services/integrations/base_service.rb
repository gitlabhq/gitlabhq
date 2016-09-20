module Integrations
  class BaseService < ::BaseService
    def execute
      resource =
        if resource_id
          find_resource
        else
          collection.search(params[:text]).limit(10)
        end

      generate_response(resource)
    end

    private

    def klass
      raise NotImplementedError
    end

    def find_resource
      collection.find_by(iid: resource_id)
    end

    def title(*args)
      raise NotImplementedError
    end

    def link(*args)
      raise NotImplementedError
    end

    def resource_id
      if params[:text].is_a?(Integer) || params[:text].match(/\A\d+\z/)
        params[:text].to_i
      else
        nil
      end
    end

    def fallback(*args)
      raise NotImplementedError
    end

    def collection
      klass.where(project: project)
    end

    def generate_response(resource)
      if resource.nil?
        respond_404
      elsif resource.respond_to?(:count)
        return generate_response(resource.first) if resource.count == 1
        return no_search_results if resource.empty?

        {
          response_type: :ephemeral,
          text: "Search results for #{params[:text]}",
          attachments: resource.map { |item| small_attachment(item) }
        }
      else
        {
          response_type: :in_channel,
          attachments: [ large_attachment(resource) ]
        }
      end
    end

    def slack_format(message)
      Slack::Notifier::LinkFormatter.format(message)
    end

    def no_search_results
      {
        text: "No search results for #{params[:text]}. :(",
        response_type: :ephemeral
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
        color: "#C95823"
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
