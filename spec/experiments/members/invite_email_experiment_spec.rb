# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteEmailExperiment do
  subject(:invite_email) { experiment('members/invite_email', **context) }

  let(:context) { { actor: double('Member', created_by: double('User', avatar_url: '_avatar_url_')) } }

  before do
    allow(invite_email).to receive(:enabled?).and_return(true)
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

  describe "variant resolution", :clean_gitlab_redis_shared_state do
    it "proves out round robin in variant selection", :aggregate_failures do
      instance_1 = described_class.new('members/invite_email', **context)
      allow(instance_1).to receive(:enabled?).and_return(true)
      instance_2 = described_class.new('members/invite_email', **context)
      allow(instance_2).to receive(:enabled?).and_return(true)
      instance_3 = described_class.new('members/invite_email', **context)
      allow(instance_3).to receive(:enabled?).and_return(true)

      instance_1.try { }

      expect(instance_1.variant.name).to eq('permission_info')

      instance_2.try { }

      expect(instance_2.variant.name).to eq('control')

      instance_3.try { }

      expect(instance_3.variant.name).to eq('avatar')
    end
  end
end
