# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Emojis (JavaScript fixtures)', type: :request do
  include JavaScriptFixturesHelpers

  before(:all) do
    clean_frontend_fixtures('emojis/')
  end

  it 'emojis/emojis.json' do |example|
    get '/-/emojis/1/emojis.json'

    expect(response).to be_successful
  end
end
