# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UsageQuotasController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  describe 'GET #index' do
    render_views

    it 'does not render search settings partial' do
      sign_in(user)
      get(:index, params: { namespace_id: user.namespace, project_id: project })

      expect(response).to render_template('index')
      expect(response).not_to render_template('shared/search_settings')
    end
  end
end
