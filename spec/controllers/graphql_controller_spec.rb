require 'spec_helper'

describe GraphqlController do
  describe 'execute' do
    before do
      sign_in(user) if user

      run_test_query!
    end

    subject { query_response }

    context 'graphql is disabled by feature flag' do
      let(:user) { nil }

      before do
        stub_feature_flags(graphql: false)
      end

      it 'returns 404' do
        run_test_query!

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'signed out' do
      let(:user) { nil }

      it 'runs the query with current_user: nil' do
        is_expected.to eq('echo' => 'nil says: test success')
      end
    end

    context 'signed in' do
      let(:user) { create(:user, username: 'Simon') }

      it 'runs the query with current_user set' do
        is_expected.to eq('echo' => '"Simon" says: test success')
      end
    end
  end

  # Chosen to exercise all the moving parts in GraphqlController#execute
  def run_test_query!
    query = <<~QUERY
      query Echo($text: String) {
        echo(text: $text)
      }
    QUERY

    post :execute, query: query, operationName: 'Echo', variables: { 'text' => 'test success' }
  end

  def query_response
    json_response['data']
  end
end
