# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Populate new pipeline CI variables with url params", :js, feature_category: :ci_variables do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:page_path) { new_project_pipeline_path(project) }

  before do
    sign_in(user)
    project.add_maintainer(user)

    visit "#{page_path}?var[key1]=value1&file_var[key2]=value2"
  end

  it "var[key1]=value1 populates env_var variable correctly" do
    page.within(all("[data-testid='ci-variable-row-container']")[0]) do
      expect(find_by_testid('pipeline-form-ci-variable-key-field').value).to eq('key1')
      expect(find_by_testid('pipeline-form-ci-variable-value-field').value).to eq('value1')
    end
  end

  it "file_var[key2]=value2 populates file variable correctly" do
    page.within(all("[data-testid='ci-variable-row-container']")[1]) do
      expect(find_by_testid('pipeline-form-ci-variable-key-field').value).to eq('key2')
      expect(find_by_testid('pipeline-form-ci-variable-value-field').value).to eq('value2')
    end
  end
end
