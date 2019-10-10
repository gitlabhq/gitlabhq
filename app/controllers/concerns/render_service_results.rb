# frozen_string_literal: true

module RenderServiceResults
  extend ActiveSupport::Concern

  def success_response(result)
    render({
      status: result[:http_status],
      json: result[:body]
    })
  end

  def continue_polling_response
    render({
      status: :no_content,
      json: {
        status: _('processing'),
        message: _('Not ready yet. Try again later.')
      }
    })
  end

  def error_response(result)
    render({
      status: result[:http_status] || :bad_request,
      json: { status: result[:status], message: result[:message] }
    })
  end
end
