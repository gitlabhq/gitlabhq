class NoticesController < ApplicationController

  class ParamsError < StandardError; end

  skip_before_action :authenticate_user!, only: :create
  skip_before_action :verify_authenticity_token, only: :create

  rescue_from ParamsError, with: :bad_params

  def create
    # params[:data] if the notice came from a GET request, raw_post if it came via POST
    report = ErrorReport.new(notice_params)

    if report.valid?
      report.generate_err!
      api_xml = report.err.to_xml(only: false, methods: [:id]) do |xml|
        xml.id report.err.id
      end
      render xml: api_xml
    else
      render text: "Your API key is unknown", status: 422
    end
  end

  def locate
    err = Err.find(params[:id])
    redirect_to application_err_path(err.application, err)
  end

  private

  def notice_params
    return @notice_params if @notice_params
    @notice_params = params[:data] || request.raw_post
    if @notice_params.blank?
      raise ParamsError.new('Need a data params in GET or raw post data')
    end
    @notice_params
  end

  def bad_params(exception)
    render text: exception.message, status: :bad_request
  end

end
