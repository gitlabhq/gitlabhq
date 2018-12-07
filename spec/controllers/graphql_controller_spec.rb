require 'spec_helper'

describe GraphqlController do
  describe 'execute' do
    let(:user) { nil }

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

    context 'invalid variables' do
      it 'returns an error' do
        run_test_query!(variables: "This is not JSON")

        expect(response).to have_gitlab_http_status(422)
        expect(json_response['errors'].first['message']).not_to be_nil
      end
    end
  end

  context 'token authentication' do
    before do
      stub_authentication_activity_metrics(debug: false)
    end

    let(:user) { create(:user, username: 'Simon') }
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    context "when the 'personal_access_token' param is populated with the personal access token" do
      it 'logs the user in' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
                .and increment(:user_session_override_counter)
                       .and increment(:user_sessionless_authentication_counter)

        run_test_query!(private_token: personal_access_token.token)

        expect(response).to have_gitlab_http_status(200)
        expect(query_response).to eq('echo' => '"Simon" says: test success')
      end
    end

    context 'when the personal access token has no api scope' do
      it 'does not log the user in' do
        personal_access_token.update(scopes: [:read_user])

        run_test_query!(private_token: personal_access_token.token)

        expect(response).to have_gitlab_http_status(200)

        expect(query_response).to eq('echo' => 'nil says: test success')
      end
    end

    context 'without token' do
      it 'shows public data' do
        run_test_query!

        expect(query_response).to eq('echo' => 'nil says: test success')
      end
    end
  end

  # Chosen to exercise all the moving parts in GraphqlController#execute
  def run_test_query!(variables: { 'text' => 'test success' }, private_token: nil)
    query = <<~QUERY
      query Echo($text: String) {
        echo(text: $text)
      }
    QUERY

    post :execute, query: query, operationName: 'Echo', variables: variables, private_token: private_token
  end

  def query_response
    json_response['data']
  end
end
