# frozen_string_literal: true

RSpec.describe QA::Runtime::API::Client do
  before do
    allow(QA::Runtime::Env).to receive_messages({ personal_access_token: nil, admin_personal_access_token: nil })
  end

  describe "initialization" do
    it "defaults to :gitlab address" do
      expect(described_class.new(personal_access_token: "token").address).to eq :gitlab
    end

    it "uses specified address" do
      client = described_class.new("http:///example.com", personal_access_token: "token")

      expect(client.address).to eq "http:///example.com"
    end
  end

  describe "#personal_access_token" do
    subject(:client) { described_class.new(user: user, personal_access_token: personal_access_token) }

    let(:user) { nil }
    let(:personal_access_token) { nil }

    context "when user is nil and personal_access_token is set" do
      let(:personal_access_token) { "a_token" }

      it "returns specified token" do
        expect(client.personal_access_token).to eq(personal_access_token)
      end
    end

    context "when user is set and personal_access_token is nil" do
      let(:existing_pat) { nil }
      let(:new_pat) { QA::Resource::PersonalAccessToken.init { |token| token.token = "a_token" } }

      let(:user) do
        instance_double(QA::Resource::User, create_personal_access_token!: new_pat, personal_access_token: existing_pat)
      end

      context "when user does not have existing token" do
        it "creates token from user resource" do
          expect(client.personal_access_token).to eq("a_token")
        end
      end

      context "when user has existing token" do
        let(:existing_pat) { QA::Resource::PersonalAccessToken.init { |token| token.token = "token" } }

        it "uses existing token" do
          expect(client.personal_access_token).to eq("token")
        end
      end
    end

    context "when user is nil and personal_access_token is nil" do
      it "raises an error" do
        expect { client }.to raise_error(ArgumentError, "either user or personal_access_token must be provided")
      end
    end

    context "when user is present and personal_access_token is present" do
      let(:user) { instance_double(QA::Resource::User, create_personal_access_token!: nil) }
      let(:personal_access_token) { "token" }

      it "does not create new token" do
        expect(client.personal_access_token).to eq(personal_access_token)
        expect(user).not_to have_received(:create_personal_access_token!)
      end
    end
  end
end
