# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Populate new pipeline CI variables with url params", :js, feature_category: :pipeline_authoring do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:page_path) { new_project_pipeline_path(project) }

  shared_examples 'form pre-filled with URL params' do
    before do
      sign_in(user)
      project.add_maintainer(user)

      visit "#{page_path}?var[key1]=value1&file_var[key2]=value2"
    end

    it "var[key1]=value1 populates env_var variable correctly" do
      page.within(all("[data-testid='ci-variable-row']")[0]) do
        expect(find("[data-testid='pipeline-form-ci-variable-key']").value).to eq('key1')
        expect(find("[data-testid='pipeline-form-ci-variable-value']").value).to eq('value1')
      end
    end

    it "file_var[key2]=value2 populates file variable correctly" do
      page.within(all("[data-testid='ci-variable-row']")[1]) do
        expect(find("[data-testid='pipeline-form-ci-variable-key']").value).to eq('key2')
        expect(find("[data-testid='pipeline-form-ci-variable-value']").value).to eq('value2')
      end
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(run_pipeline_graphql: false)
    end

    it_behaves_like 'form pre-filled with URL params'
  end

  context 'when feature flag is enabled' do
    before do
      stub_feature_flags(run_pipeline_graphql: true)
    end

    it_behaves_like 'form pre-filled with URL params'
  end
end
