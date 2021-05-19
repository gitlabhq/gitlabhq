# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedirectsForMissingPathOnTree, type: :controller do
  controller(ActionController::Base) do
    include Gitlab::Routing.url_helpers
    include RedirectsForMissingPathOnTree

    def fake
      redirect_to_tree_root_for_missing_path(Project.find(params[:project_id]), params[:ref], params[:file_path])
    end
  end

  let(:project) { create(:project) }

  before do
    routes.draw { get 'fake' => 'anonymous#fake' }
  end

  describe '#redirect_to_root_path' do
    it 'redirects to the tree path with a notice' do
      long_file_path = ('a/b/' * 30) + 'foo.txt'
      truncated_file_path = '...b/' + ('a/b/' * 12) + 'foo.txt'
      expected_message = "\"#{truncated_file_path}\" did not exist on \"theref\""

      get :fake, params: { project_id: project.id, ref: 'theref', file_path: long_file_path }

      expect(response).to redirect_to project_tree_path(project, 'theref')
      expect(controller).to set_flash[:notice].to eq(expected_message)
    end
  end
end
