# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DefaultBranchProtection, feature_category: :source_code_management do
  let(:controller_class) do
    # rubocop:disable Rails/ApplicationController -- the concern only needs params
    Class.new(ActionController::Base) do
      include DefaultBranchProtection
    end
    # rubocop:enable Rails/ApplicationController
  end

  let(:permitted_params) { ActionController::Parameters.new(request_params).permit! }

  subject(:controller) { controller_class.new }

  before do
    allow(controller).to receive(:params).and_return(permitted_params)
  end

  describe '#normalize_default_branch_params!' do
    context 'when the form key is absent' do
      let(:request_params) { {} }

      it 'returns nil instead of raising ParameterMissing' do
        expect(controller.normalize_default_branch_params!(:group)).to be_nil
      end
    end

    context 'when the form key holds an empty hash' do
      let(:request_params) { { group: {} } }

      it 'returns nil instead of raising ParameterMissing' do
        expect(controller.normalize_default_branch_params!(:group)).to be_nil
      end
    end

    context 'when default_branch_protected is false' do
      let(:request_params) { { group: { default_branch_protected: 'false' } } }

      it 'replaces the defaults with no protection' do
        controller.normalize_default_branch_params!(:group)

        expect(permitted_params[:group][:default_branch_protection_defaults].to_unsafe_h.deep_symbolize_keys)
          .to eq(::Gitlab::Access::BranchProtection.protection_none.deep_symbolize_keys)
      end
    end

    context 'when default_branch_protection_defaults is submitted' do
      let(:request_params) do
        {
          group: {
            default_branch_protection_level: '2',
            default_branch_protection_defaults: {
              allowed_to_push: [{ access_level: '30' }],
              allowed_to_merge: [{ access_level: '40' }],
              allow_force_push: 'true',
              code_owner_approval_required: 'false'
            }
          }
        }
      end

      it 'casts access levels and flags, and drops the legacy protection level' do
        controller.normalize_default_branch_params!(:group)

        settings = permitted_params[:group]
        defaults = settings[:default_branch_protection_defaults]

        expect(settings).not_to have_key(:default_branch_protection_level)
        expect(defaults[:allowed_to_push].map { |entry| entry[:access_level] }).to eq([30])
        expect(defaults[:allowed_to_merge].map { |entry| entry[:access_level] }).to eq([40])
        expect(defaults[:allow_force_push]).to be(true)
        expect(defaults[:code_owner_approval_required]).to be(false)
      end
    end

    context 'when default_branch_protection_defaults is not submitted' do
      let(:request_params) { { group: { name: 'a group' } } }

      it 'leaves the params untouched' do
        expect(controller.normalize_default_branch_params!(:group)).to eq(permitted_params[:group])
        expect(permitted_params[:group].to_h).to eq({ 'name' => 'a group' })
      end
    end
  end
end
