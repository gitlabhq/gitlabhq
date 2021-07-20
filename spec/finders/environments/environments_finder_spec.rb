# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::EnvironmentsFinder do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.creator }
  let_it_be(:environment) { create(:environment, :available, project: project) }
  let_it_be(:environment_stopped) { create(:environment, :stopped, name: 'test2', project: project) }
  let_it_be(:environment_available) { create(:environment, :available, name: 'test3', project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'with states parameter' do
      let_it_be(:stopped_environment) { create(:environment, :stopped, project: project) }

      it 'returns environments with the requested state' do
        result = described_class.new(project, user, states: 'available').execute

        expect(result).to contain_exactly(environment, environment_available)
      end

      it 'returns environments with any of the requested states' do
        result = described_class.new(project, user, states: %w(available stopped)).execute

        expect(result).to contain_exactly(environment, environment_stopped, environment_available, stopped_environment)
      end

      it 'raises exception when requested state is invalid' do
        expect { described_class.new(project, user, states: %w(invalid stopped)).execute }.to(
          raise_error(described_class::InvalidStatesError, 'Requested states are invalid')
        )
      end

      context 'works with symbols' do
        it 'returns environments with the requested state' do
          result = described_class.new(project, user, states: :available).execute

          expect(result).to contain_exactly(environment, environment_available)
        end

        it 'returns environments with any of the requested states' do
          result = described_class.new(project, user, states: [:available, :stopped]).execute

          expect(result).to contain_exactly(environment, environment_stopped, environment_available, stopped_environment)
        end
      end
    end

    context 'with search and states' do
      it 'searches environments by name and state' do
        result = described_class.new(project, user, search: 'test', states: :available).execute

        expect(result).to contain_exactly(environment_available)
      end
    end

    context 'with id' do
      it 'searches environments by name and state' do
        result = described_class.new(project, user, search: 'test', environment_ids: [environment_available.id]).execute

        expect(result).to contain_exactly(environment_available)
      end
    end
  end
end
