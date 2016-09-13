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

    def resource_id
      if params[:text].is_a?(Integer) || params[:text].match(/\A\d+\z/)
        params[:text].to_i
      else
        nil
      end
    end

    def klass
      raise NotImplementedError
    end

    def find_resource
      raise NotImplementedError
    end

    def title
      raise NotImplementedError
    end

    def link(*args)
      raise NotImplementedError
    end

    # Used when returning a collection
    def to_attachment(resource)
      {
          "title": "Title",
          "text": "Testing *right now!*",
          "mrkdwn_in": [
              "text",
              "pretext"
          ]
      }
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
          text: "Search results for #{params[:text]}",
          response_type: :ephemeral,
          attachments: resource.map { |item| to_attachment(item) }
        }
      else
        {
          text: slack_format(title(resource)),
          response_type: :in_channel,
          mrkdwn_in: [
              :text,
              :pretext
          ]
        }
      end
    end

    def slack_format(message)
      Slack::Notifier::LinkFormatter.format(message)
    end

    def no_search_results
      {
        text: "No search results for #{params[:text]}. :(",
        response_type: :ephemeral,
        attachments: []
      }
    end

    def respond_404
      {
        text: "404 not found! Please make you use the right identifier. :boom:",
        response_type: :ephemeral
      }
    end
  end
end
