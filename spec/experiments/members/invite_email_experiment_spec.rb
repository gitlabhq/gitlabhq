# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteEmailExperiment do
  subject do
    experiment('members/invite_email', actor: double('Member', created_by: double('User', avatar_url: '_avatar_url_')))
  end

  before do
    allow(subject).to receive(:enabled?).and_return(true)
  end

  describe "variant resolution" do
    it "returns nil when not rolled out" do
      stub_feature_flags(members_invite_email: false)

      expect(subject.variant.name).to eq('control')
    end

    context "when rolled out to 100%" do
      it "returns the first variant name" do
        subject.try(:avatar) {}

        expect(subject.variant.name).to eq('avatar')
      end
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
