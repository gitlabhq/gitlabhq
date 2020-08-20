# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Populate new pipeline CI variables with url params", :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:page_path) { new_project_pipeline_path(project) }

  before do
    stub_feature_flags(new_pipeline_form: false)
    sign_in(user)
    project.add_maintainer(user)

    visit "#{page_path}?var[key1]=value1&file_var[key2]=value2"
  end

  it "var[key1]=value1 populates env_var variable correctly" do
    page.within('.ci-variable-list .js-row:nth-child(1)') do
      expect(find('.js-ci-variable-input-variable-type').value).to eq('env_var')
      expect(find('.js-ci-variable-input-key').value).to eq('key1')
      expect(find('.js-ci-variable-input-value').text).to eq('value1')
    end
  end

  it "file_var[key2]=value2 populates file variable correctly" do
    page.within('.ci-variable-list .js-row:nth-child(2)') do
      expect(find('.js-ci-variable-input-variable-type').value).to eq('file')
      expect(find('.js-ci-variable-input-key').value).to eq('key2')
      expect(find('.js-ci-variable-input-value').text).to eq('value2')
    end
  end
end
