# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalLinkHelper do
  include IconsHelper

  it 'returns external link with icon' do
    link = external_link('https://gitlab.com', 'https://gitlab.com').to_s
    expect(link).to start_with('<a target="_blank" rel="noopener noreferrer" href="https://gitlab.com">https://gitlab.com')
    expect(link).to include('data-testid="external-link-icon"')
  end

  it 'allows options when creating external link with icon' do
    link = external_link('https://gitlab.com', 'https://gitlab.com', { "data-foo": "bar", class: "externalLink" }).to_s
    expect(link).to start_with('<a target="_blank" rel="noopener noreferrer" data-foo="bar" class="externalLink" href="https://gitlab.com">https://gitlab.com')
    expect(link).to include('data-testid="external-link-icon"')
  end

  it 'sanitizes and returns external link with icon' do
    link = external_link('sanitized link content', 'javascript:alert()').to_s
    expect(link).not_to include('href="javascript:alert()"')
    expect(link).to start_with('<a target="_blank" rel="noopener noreferrer">sanitized link content')
    expect(link).to include('data-testid="external-link-icon"')
  end
end
