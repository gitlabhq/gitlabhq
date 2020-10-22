# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ContainerRepositoriesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be(:container_repositories) { create(:container_repository, project: project) }

  let(:args) { {} }

  describe '#resolve' do
    let(:object) { project }

    subject { resolve(described_class, ctx: { current_user: user }, args: args, obj: object) }

    shared_examples 'returning container repositories' do
      it { is_expected.to contain_exactly(container_repositories) }

      context 'with a named search' do
        let_it_be(:named_container_repository) { create(:container_repository, project: project, name: 'Foobar') }

        let(:args) { { name: 'ooba' } }

        it { is_expected.to contain_exactly(named_container_repository) }
      end
    end

    context 'with authorized user' do
      before do
        group.add_user(user, :maintainer)
      end

      context 'when the object is a project' do
        it_behaves_like 'returning container repositories'
      end

      context 'when the object is a group' do
        let(:object) { group }

        it_behaves_like 'returning container repositories'
      end

      context 'when the object is an invalid type' do
        let(:object) { Object.new }

        it { expect { subject }.to raise_exception('invalid subject_type') }
      end
    end

    context 'with unauthorized user' do
      it { is_expected.to be nil }
    end
  end
end
