# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Zuora content security policy', feature_category: :purchase do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'has proper Content Security Policy headers' do
    visit pipeline_path(pipeline)

    expect(response_headers['Content-Security-Policy']).to include('https://*.zuora.com')
  end
end
