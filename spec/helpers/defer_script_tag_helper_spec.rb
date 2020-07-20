# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeferScriptTagHelper do
  describe 'script tag' do
    script_url = 'test.js'

    it 'returns an script tag with defer=true' do
      expect(javascript_include_tag(script_url).to_s)
        .to eq "<script src=\"/javascripts/#{script_url}\" defer=\"defer\"></script>"
    end
  end
end
