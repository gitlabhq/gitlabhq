# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TerraformHelper do
  describe '#js_terraform_list_data' do
    let_it_be(:project) { create(:project) }

    subject { helper.js_terraform_list_data(project) }

    it 'displays image path' do
      image_path = ActionController::Base.helpers.image_path(
        'illustrations/empty-state/empty-serverless-lg.svg'
      )

      expect(subject[:empty_state_image]).to eq(image_path)
    end

    it 'displays project path' do
      expect(subject[:project_path]).to eq(project.full_path)
    end
  end
end
