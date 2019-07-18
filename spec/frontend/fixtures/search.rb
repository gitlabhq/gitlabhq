require 'spec_helper'

describe SearchController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  render_views

  before(:all) do
    clean_frontend_fixtures('search/')
  end

  it 'search/show.html' do
    get :show

    expect(response).to be_successful
  end
end
