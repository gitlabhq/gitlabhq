# frozen_string_literal: true

module Organizations
  class BaseService
    include BaseServiceUtility

    attr_reader :current_user, :params

    def initialize(current_user: nil, params: {})
      @current_user = current_user
      @params = params.dup
      return unless @params.key?(:description)

      organization_detail_attributes = { description: @params.delete(:description) }
      @params[:organization_detail_attributes] ||= {}
      @params[:organization_detail_attributes].merge!(organization_detail_attributes)
    end
  end
end
