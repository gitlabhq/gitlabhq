# frozen_string_literal: true

require 'spec_helper'

describe Projects::GitHttpController do
  describe 'HEAD #info_refs' do
    it 'returns 403' do
      project = create(:project, :public, :repository)

      head :info_refs, params: { namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

      expect(response.status).to eq(403)
    end
  end
end
