# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::LabelsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, reporters: user) }
  let_it_be(:project_2) { create(:project, reporters: user) }

  let_it_be(:label) { create(:label, project: project, title: 'some_label') }
  let_it_be(:label_with_same_title) { create(:label, project: project_2, title: 'some_label') }
  let_it_be(:unrelated_label) { create(:label, project: create(:project, :public)) }

  before do
    sign_in(user)
  end

  describe "#index" do
    subject { get :index, format: :json }

    it 'returns labels with unique titles for projects the user has a relationship with' do
      subject

      expect(json_response).to be_kind_of(Array)
      expect(json_response.size).to eq(1)
      expect(json_response[0]['title']).to eq(label.title)
    end

    it_behaves_like 'disabled when using an external authorization service'
  end
end
