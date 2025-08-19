# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User factory', feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  describe 'associate an organization' do
    let_it_be(:project) { create(:project) }
    let_it_be(:organization1) { create(:organization, :public) }
    let_it_be(:organization2) { create(:organization, :public) }
    let_it_be(:owner_of_organization) { create(:organization, :public, name: 'Owned Organization') }

    let_it_be(:common_organization) { create(:common_organization) }

    subject(:created_factory) do
      if organizations.nil? # prevent assigning 'nil', user.organizations is an array
        create(:user, organization: organization, owner_of: owner_of).reload
      else
        create(:user, organization: organization, organizations: organizations, owner_of: owner_of).reload
      end
    end

    # rubocop:disable Layout/LineLength -- Table syntax.
    where(:organization, :organizations, :owner_of, :assigned_organization, :member_organizations) do
      # When organization is nil (assigned_organization defaults to common_organization)
      nil                 | nil                                        | nil                         | ref(:common_organization)   | [ref(:common_organization)]
      nil                 | []                                         | nil                         | ref(:common_organization)   | []
      nil                 | [ref(:organization2), ref(:organization1)] | nil                         | ref(:organization2)         | [ref(:organization1), ref(:organization2)]
      nil                 | [ref(:organization2), ref(:organization1)] | ref(:owner_of_organization) | ref(:organization2)         | [ref(:organization1), ref(:organization2), ref(:owner_of_organization)]
      nil                 | nil                                        | ref(:owner_of_organization) | ref(:owner_of_organization) | [ref(:owner_of_organization)]

      # When organization is organization1 (assigned_organization matches organization)
      ref(:organization1) | nil                                        | nil                         | ref(:organization1)       | [ref(:organization1)]
      ref(:organization1) | []                                         | nil                         | ref(:organization1)       | []
      ref(:organization1) | [ref(:organization2), ref(:organization1)] | nil                         | ref(:organization1)       | [ref(:organization1), ref(:organization2)]
      ref(:organization1) | [ref(:organization2), ref(:organization1)] | ref(:owner_of_organization) | ref(:organization1)       | [ref(:organization1), ref(:organization2), ref(:owner_of_organization)]

      # owner_of does not has to be an Organization instance
      nil                 | nil                                        | ref(:project)               | ref(:common_organization) | [ref(:common_organization)]
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'associates an organization' do
        expect(created_factory.organizations).to match_array(member_organizations)
        expect(created_factory.organization).to eq(assigned_organization)

        expect(owner_of.owner?(created_factory)).to be(true) if owner_of.is_a?(Organizations::Organization)
      end
    end
  end

  describe 'personal namespace creation' do
    subject(:created_user) { create(:user) }

    context 'when UserWithNamespaceShim is disabled' do
      before do
        allow(UserWithNamespaceShim).to receive(:enabled?).and_return(false)
      end

      it 'does not create a namespace' do
        expect(created_user.namespace).to be_nil
      end
    end

    context 'when UserWithNamespaceShim is enabled' do
      before do
        allow(UserWithNamespaceShim).to receive(:enabled?).and_return(true)
      end

      it 'does create a namespace' do
        expect(created_user.namespace).to be_instance_of(Namespaces::UserNamespace)
      end

      it 'does create a namespace with the same organization' do
        expect(created_user.namespace.organization).to eq(created_user.organization)
      end

      context 'when an organization is specified' do
        let_it_be(:organization) { create(:organization) }

        subject(:creted_user) { create(:user, organization: organization) }

        it 'does create a namespace with the same organization' do
          expect(created_user.namespace.organization).to eq(created_user.organization)
        end
      end
    end

    context 'when using with_namespace trait' do
      subject(:created_user) { create(:user, :with_namespace) }

      it 'does create a namespace with the same organization' do
        expect(created_user.namespace.organization).to eq(created_user.organization)
      end
    end
  end
end
