# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Labels::Create do
  let_it_be(:user) { create(:user) }

  let(:attributes) do
    {
      title: 'new title',
      description: 'A new label'
    }
  end

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:mutated_label) { subject[:label] }

  shared_examples 'create labels mutation' do
    describe '#resolve' do
      subject { mutation.resolve(attributes.merge(extra_params)) }

      context 'when the user does not have permission to create a label' do
        before do
          parent.add_guest(user)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the user can create a label' do
        before do
          parent.add_developer(user)
        end

        it 'creates label with correct values' do
          expect(mutated_label).to have_attributes(attributes)
        end
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_label) }

  context 'when creating a project label' do
    let_it_be(:parent) { create(:project) }

    let(:extra_params) { { project_path: parent.full_path } }

    it_behaves_like 'create labels mutation'
  end

  context 'when creating a group label' do
    let_it_be(:parent) { create(:group) }

    let(:extra_params) { { group_path: parent.full_path } }

    it_behaves_like 'create labels mutation'
  end

  describe '#ready?' do
    subject { mutation.ready?(**attributes.merge(extra_params)) }

    context 'when passing both project_path and group_path' do
      let(:extra_params) { { project_path: 'foo', group_path: 'bar' } }

      it 'raises an argument error' do
        expect { subject }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /Exactly one of/)
      end
    end

    context 'when passing only project_path or group_path' do
      let(:extra_params) { { project_path: 'foo' } }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
