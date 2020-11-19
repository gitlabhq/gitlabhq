# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerSetupResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let(:user) { create(:user) }

    subject(:resolve_subject) { resolve(described_class, ctx: { current_user: user }, args: { platform: platform, architecture: 'amd64' }.merge(target_param)) }

    context 'with container platforms' do
      let(:platform) { 'docker' }
      let(:project) { create(:project) }
      let(:target_param) { { project_id: project.to_global_id } }

      it 'returns install instructions' do
        expect(resolve_subject[:install_instructions]).not_to eq(nil)
      end

      it 'does not return register instructions' do
        expect(resolve_subject[:register_instructions]).to eq(nil)
      end
    end

    context 'with regular platforms' do
      let(:platform) { 'linux' }

      context 'without target parameter' do
        let(:target_param) { {} }

        context 'when user is not admin' do
          it 'returns access error' do
            expect { resolve_subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when user is admin' do
          before do
            user.update!(admin: true)
          end

          it 'returns install and register instructions' do
            expect(resolve_subject.keys).to contain_exactly(:install_instructions, :register_instructions)
            expect(resolve_subject.values).not_to include(nil)
          end
        end
      end

      context 'with project target parameter' do
        let(:project) { create(:project) }
        let(:target_param) { { project_id: project.to_global_id } }

        context 'when user has access to admin builds on project' do
          before do
            project.add_maintainer(user)
          end

          it 'returns install and register instructions' do
            expect(resolve_subject.keys).to contain_exactly(:install_instructions, :register_instructions)
            expect(resolve_subject.values).not_to include(nil)
          end
        end

        context 'when user does not have access to admin builds on project' do
          before do
            project.add_developer(user)
          end

          it 'returns access error' do
            expect { resolve_subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'with group target parameter' do
        let(:group) { create(:group) }
        let(:target_param) { { group_id: group.to_global_id } }

        context 'when user has access to admin builds on group' do
          before do
            group.add_owner(user)
          end

          it 'returns install and register instructions' do
            expect(resolve_subject.keys).to contain_exactly(:install_instructions, :register_instructions)
            expect(resolve_subject.values).not_to include(nil)
          end
        end

        context 'when user does not have access to admin builds on group' do
          before do
            group.add_developer(user)
          end

          it 'returns access error' do
            expect { resolve_subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end
    end
  end
end
