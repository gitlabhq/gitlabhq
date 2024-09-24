# frozen_string_literal: true

RSpec.describe QA::Tools::ReadinessCheck do
  subject(:readiness_check) { described_class.new(wait: wait) }

  let(:url) { "example.com" }
  let(:wait) { 1 }
  let(:msg_base) { "Gitlab readiness check failed, valid sign_in page did not appear within #{wait} seconds!" }

  let(:response) { instance_double(RestClient::Response, code: code, body: body) }
  let(:code) { 200 }
  let(:body) { "" }

  before do
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
        "#{msg_base} Got unsucessfull response code: #{code}"
      )
    end
  end

  context "with request timeout" do
    before do
      allow(readiness_check).to receive(:get).and_raise(RestClient::Exceptions::OpenTimeout)
    end

    it "raises an error on validation" do
      expect { readiness_check.perform }.to raise_error("#{msg_base} Timed out connecting to server")
    end
  end
end
