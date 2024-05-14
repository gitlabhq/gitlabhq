# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagsUserListsFinder do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  describe '#execute' do
    it 'returns user lists' do
      finder = described_class.new(project, user, {})
      user_list = create(:operations_feature_flag_user_list, project: project)

      expect(finder.execute).to contain_exactly(user_list)
    end

    context 'with search' do
      it 'returns only matching user lists' do
        create(:operations_feature_flag_user_list, name: 'do not find', project: project)
        user_list = create(:operations_feature_flag_user_list, name: 'testing', project: project)
        finder = described_class.new(project, user, { search: "test" })

        expect(finder.execute).to contain_exactly(user_list)
      end
    end
  end
end
