# frozen_string_literal: true
require 'spec_helper'

describe RoadmapsHelper do
  describe '#roadmap_layout' do
    before do
      allow(helper).to receive(:current_user) { user }
    end

    context 'guest' do
      let(:user) { nil }

      it 'is sourced from params if exists' do
        allow(helper).to receive(:params).and_return(layout: 'WEEKS')

        expect(helper.roadmap_layout).to eq('WEEKS')
      end

      it 'returns default if params do not exist' do
        allow(helper).to receive(:params).and_return({})

        expect(helper.roadmap_layout).to eq('MONTHS')
      end
    end

    context 'logged in' do
      let(:user) { double(:user) }

      it 'is sourced from User#roadmap_layout' do
        allow(helper).to receive(:params).and_return(layout: 'WEEKS')
        expect(user).to receive(:roadmap_layout).and_return('quarters')

        expect(helper.roadmap_layout).to eq('QUARTERS')
      end
    end
  end
end
