# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsFinder::Params do
  let(:user) { create(:user) }

  subject { described_class.new(params, user, MergeRequest) }

  describe 'attention' do
    context 'attention param exists' do
      let(:params) { { attention: user.username } }

      it { expect(subject.attention).to eq(user) }
    end

    context 'attention param does not exist' do
      let(:params) { { attention: nil } }

      it { expect(subject.attention).to eq(nil) }
    end
  end
end
