# frozen_string_literal: true

RSpec.describe QA::Tools::ReadinessCheck do
  subject(:readiness_check) { described_class.new(wait: wait) }

  let(:url) { "example.com" }
  let(:wait) { 1 }
  let(:msg_base) { "Gitlab readiness check failed, valid sign_in page did not appear within #{wait} seconds! Reason:" }
  let(:live_env) { false }

  let(:response) { instance_double(RestClient::Response, code: code, body: body, headers: headers) }
  let(:code) { 200 }
  let(:body) { "" }
  let(:headers) { {} }

  before do
    allow(Capybara).to receive_message_chain("current_session.using_wait_time").and_yield
    allow(QA::Runtime::Env).to receive(:running_on_live_env?).and_return(live_env)
    allow(QA::Support::GitlabAddress).to receive(:address_with_port).with(with_default_port: false).and_return(url)
    allow(readiness_check).to receive(:get).with("#{url}/users/sign_in").and_return(response)
  end

  context "with successfull response" do
    let(:body) do
      <<~HTML
        <!DOCTYPE html>
          <body data-testid="login-page">
          </body>
        </html>
      HTML
    end

    it "validates readiness" do
      expect { readiness_check.perform }.not_to raise_error
    end
  end

  context "with missing sign in form" do
    let(:body) do
      <<~HTML
        <!DOCTYPE html>
        </html>
      HTML
    end

    it "raises an error on validation" do
      expect { readiness_check.perform }.to raise_error(/#{msg_base} Sign in page missing required elements/)
    end
  end

  context "with unsuccessfull response code" do
    let(:code) { 500 }

    it "raises an error on validation" do
      expect { readiness_check.perform }.to raise_error(
        "#{msg_base} Got unsucessfull response code from #{url}/users/sign_in: #{code}"
      )
    end
  end

  context "with request timeout" do
    before do
      allow(readiness_check).to receive(:get).and_raise(RestClient::Exceptions::OpenTimeout)
    end

    it "raises an error on validation" do
      expect { readiness_check.perform }.to raise_error(
        "#{msg_base} Failed to obtain valid http response from example.com/users/sign_in"
      )
    end
  end

  context "with UI check" do
    shared_examples "successful ui check" do
      before do
        allow(QA::Runtime::Browser).to receive(:visit).with(:gitlab, QA::Page::Main::Login)
      end

      it "validates readiness" do
        expect { readiness_check.perform }.not_to raise_error
      end
    end

    shared_examples "unsuccessful ui check" do
      before do
        allow(QA::Runtime::Browser).to receive(:visit).with(:gitlab, QA::Page::Main::Login).and_raise("not loaded")
      end

      it "validates readiness" do
        expect { readiness_check.perform }.to raise_error("#{msg_base} not loaded")
      end
    end

    context "when running on live env" do
      let(:live_env) { true }

      it_behaves_like "successful ui check"
      it_behaves_like "unsuccessful ui check"
    end

    context "when running against cloudflare" do
      context "with server header" do
        let(:headers) { { server: "cloudflare" } }

        it_behaves_like "successful ui check"
        it_behaves_like "unsuccessful ui check"
      end

      context "with forbidden response code" do
        let(:code) { 403 }

        it_behaves_like "successful ui check"
        it_behaves_like "unsuccessful ui check"
      end
    end
  end
end
