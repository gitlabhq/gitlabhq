# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsHelper, feature_category: :groups_and_projects do
  describe '#admin_projects_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.admin_projects_app_data)).to eq(
        {
          'programming_languages' => ProgrammingLanguage.most_popular
        }
      )
    end
  end
end
