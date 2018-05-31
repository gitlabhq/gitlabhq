require 'spec_helper'

describe Gitlab::Auth::UserAuthFinders do
  include described_class

  let(:user) { create(:user) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end
  let(:request) { Rack::Request.new(env)}
  let(:params) { request.params }

  def set_param(key, value)
    request.update_param(key, value)
  end

  describe '#find_user_from_job_token' do
    let(:job) { create(:ci_build, user: user) }

    shared_examples 'find user from job token' do
      context 'when route is allowed to be authenticated' do
        let(:route_authentication_setting) { { job_token_allowed: true } }

        it "returns an Unauthorized exception for an invalid token" do
          set_token('invalid token')

          expect { find_user_from_job_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end

        it "return user if token is valid" do
          set_token(job.token)

          expect(find_user_from_job_token).to eq(user)
        end
      end

      context 'when route is not allowed to be authenticated' do
        let(:route_authentication_setting) { { job_token_allowed: false } }

        it "sets current_user to nil" do
          set_token(job.token)
          allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(true)

          expect(find_user_from_job_token).to be_nil
        end
      end
    end

    context 'when the job token is in the headers' do
      def set_token(token)
        env[Gitlab::Auth::UserAuthFinders::JOB_TOKEN_HEADER] = token
      end

      it_behaves_like 'find user from job token'
    end

    context 'when the job token is in the params' do
      def set_token(token)
        set_param(Gitlab::Auth::UserAuthFinders::JOB_TOKEN_PARAM, token)
      end

      it_behaves_like 'find user from job token'
    end
  end
end
