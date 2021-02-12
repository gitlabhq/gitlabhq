# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteEmailExperiment do
  subject :invite_email do
    experiment('members/invite_email', actor: double('Member', created_by: double('User', avatar_url: '_avatar_url_')))
  end

  before do
    allow(invite_email).to receive(:enabled?).and_return(true)
  end

  describe "#rollout_strategy" do
    it "resolves to round_robin" do
      expect(invite_email.rollout_strategy).to eq(:round_robin)
    end
  end

  describe "#variants" do
    it "has all the expected variants" do
      expect(invite_email.variants).to match(%i[avatar permission_info control])
    end
  end

  describe "exclusions", :experiment do
    it "excludes when created by is nil" do
      expect(experiment('members/invite_email')).to exclude(actor: double(created_by: nil))
    end

    it "excludes when avatar_url is nil" do
      member_without_avatar_url = double('Member', created_by: double('User', avatar_url: nil))

      expect(experiment('members/invite_email')).to exclude(actor: member_without_avatar_url)
    end
  end
end
