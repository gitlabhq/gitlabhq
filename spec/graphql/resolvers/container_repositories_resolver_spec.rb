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

    subject do
      resolve(
        described_class,
        ctx: { current_user: user },
        args: args,
        obj: object,
        arg_style: :internal
      )
    end

    shared_examples 'returning container repositories' do
      it { is_expected.to contain_exactly(container_repositories) }

      context 'with a named search' do
        let_it_be(:named_container_repository) { create(:container_repository, project: project, name: 'Foobar') }

        let(:args) { { name: 'ooba' } }

        it { is_expected.to contain_exactly(named_container_repository) }
      end

      context 'with a sort argument' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:sort_repository) do
          create(:container_repository, name: 'bar', project: project, created_at: 1.day.ago)
        end

        let_it_be(:sort_repository2) do
          create(:container_repository, name: 'foo', project: project, created_at: 1.hour.ago, updated_at: 1.hour.ago)
        end

        [:created_desc, :updated_asc, :name_desc].each do |order|
          context order.to_s do
            let(:args) { { sort: order } }

            it { is_expected.to eq([sort_repository2, sort_repository]) }
          end
        end

        [:created_asc, :updated_desc, :name_asc].each do |order|
          context order.to_s do
            let(:args) { { sort: order } }

            it { is_expected.to eq([sort_repository, sort_repository2]) }
          end
        end
      end
    end

    context 'with authorized user' do
      before do
        group.add_member(user, :maintainer)
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
