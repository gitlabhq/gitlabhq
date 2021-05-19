# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::EnvironmentsFinder do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:environment) { create(:environment, :available, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'with states parameter' do
      let(:stopped_environment) { create(:environment, :stopped, project: project) }

      it 'returns environments with the requested state' do
        result = described_class.new(project, user, states: 'available').execute

        expect(result).to contain_exactly(environment)
      end

      it 'returns environments with any of the requested states' do
        result = described_class.new(project, user, states: %w(available stopped)).execute

        expect(result).to contain_exactly(environment, stopped_environment)
      end

      it 'raises exception when requested state is invalid' do
        expect { described_class.new(project, user, states: %w(invalid stopped)).execute }.to(
          raise_error(described_class::InvalidStatesError, 'Requested states are invalid')
        )
      end

      context 'works with symbols' do
        it 'returns environments with the requested state' do
          result = described_class.new(project, user, states: :available).execute

          expect(result).to contain_exactly(environment)
        end

        it 'returns environments with any of the requested states' do
          result = described_class.new(project, user, states: [:available, :stopped]).execute

          expect(result).to contain_exactly(environment, stopped_environment)
        end
      end
    end

    context 'with search and states' do
      let(:environment2) { create(:environment, :stopped, name: 'test2', project: project) }
      let(:environment3) { create(:environment, :available, name: 'test3', project: project) }

      it 'searches environments by name and state' do
        result = described_class.new(project, user, search: 'test', states: :available).execute

        expect(result).to contain_exactly(environment3)
      end
    end
  end
end
