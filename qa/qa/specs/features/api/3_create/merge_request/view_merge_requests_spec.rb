# frozen_string_literal: true

require 'net/http'

module QA
  RSpec.describe 'Create' do
    describe 'Merge Requests', product_group: :code_review do
      let(:address) { Runtime::Address.new(:gitlab, '') }

      context 'with a malformed URL' do
        let(:path) { %(/-/merge_requests?sort=created_date&state=<th:t=\"%24{dfb}%23foreach) }

        it 'returns 400 or 302', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/426509' do
          # Ruby's URI module automatically encodes query parameters:
          # https://github.com/ruby/uri/blob/f4999b61daa40f2c99fdc7159e2c85c036b22c67/lib/uri/generic.rb#L849
          #
          # This gets automatically used with HTTParty and other clients. We
          # have to construct a malformed URL by building the request ourselves.
          uri = URI.parse(address.address)

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')

          request = Net::HTTP::Get.new(uri.path + path)
          response = http.request(request)

          # URL normalization in live environments can result in a 302
          # https://gitlab.com/gitlab-org/gitlab/-/issues/483173#note_2126564107
          expect(response.code.to_i).to eq(400).or eq(302)
        end
      end
    end
  end
end
