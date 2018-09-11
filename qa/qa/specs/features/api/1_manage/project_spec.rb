# frozen_string_literal: true

module QA
  describe 'Projects API' do
    before(:context) do
      @api_client = Runtime::API::Client.new(:gitlab)
      @personal_access_token = Runtime::API::Client.new.get_personal_access_token
    end


    it 'fetches projects' do
      @api_client = Runtime::API::Client.new(:gitlab, personal_access_token: @personal_access_token)

      projects_request = Runtime::API::Request.new(@api_client, "/projects")

      get projects_request.url
      expect_status(200)
    end
  end
end
