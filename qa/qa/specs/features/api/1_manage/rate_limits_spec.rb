# frozen_string_literal: true

module QA
  context 'Manage with IP rate limits', :requires_admin do
    describe 'Users API' do
      before(:context) do
        @api_client = Runtime::API::Client.new(:gitlab, ip_limits: true)
      end

      let(:request) { Runtime::API::Request.new(@api_client, '/users') }

      it 'GET /users' do
        5.times do
          get request.url
          expect_status(200)
        end
      end
    end
  end
end
