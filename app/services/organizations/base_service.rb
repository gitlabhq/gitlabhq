# frozen_string_literal: true

module Organizations
  class BaseService
    include BaseServiceUtility

    def initialize(current_user: nil, params: {})
      @current_user = current_user
      @params = params.dup

      build_organization_detail_attributes
    end

    private

    attr_reader :current_user, :params

    def build_organization_detail_attributes
      @params[:organization_detail_attributes] ||= {}

      organization_detail_attributes = [:description, :avatar]
      organization_detail_attributes.each do |attribute|
        @params[:organization_detail_attributes][attribute] = @params.delete(attribute) if @params.key?(attribute)
      end
    end
  end
end
