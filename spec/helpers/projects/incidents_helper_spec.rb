# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsHelper do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project) }
  let(:project_path) { project.full_path }

  describe '#incidents_data' do
    subject(:data) { helper.incidents_data(project) }

    it 'returns frontend configuration' do
      expect(data).to match('project-path' => project_path)
    end
  end
end
