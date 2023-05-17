# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProtectedRefsHelper, feature_category: :source_code_management do
  describe '#protected_access_levels_for_dropdowns' do
    let(:protected_access_level_dropdown_roles) { :protected_access_level_dropdown_roles }

    before do
      allow(helper)
        .to receive(:protected_access_level_dropdown_roles)
        .and_return(protected_access_level_dropdown_roles)
    end

    it 'returns roles for {create,push,merge}_access_levels' do
      expect(helper.protected_access_levels_for_dropdowns).to eq(
        {
          create_access_levels: protected_access_level_dropdown_roles,
          push_access_levels: protected_access_level_dropdown_roles,
          merge_access_levels: protected_access_level_dropdown_roles
        }
      )
    end
  end

  describe '#protected_access_level_dropdown_roles' do
    let(:roles) do
      [
        {
          id: ::Gitlab::Access::DEVELOPER,
          text: 'Developers + Maintainers',
          before_divider: true
        },
        {
          id: ::Gitlab::Access::MAINTAINER,
          text: 'Maintainers',
          before_divider: true
        },
        {
          id: ::Gitlab::Access::NO_ACCESS,
          text: 'No one',
          before_divider: true
        }
      ]
    end

    it 'returns dropdown options for each protected ref access level' do
      expect(helper.protected_access_level_dropdown_roles[:roles]).to include(*roles)
    end
  end
end
