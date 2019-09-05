# frozen_string_literal: true

require 'spec_helper'

describe ExternalLinkHelper do
  include IconsHelper

  it 'returns external link with icon' do
    expect(external_link('https://gitlab.com', 'https://gitlab.com').to_s)
      .to eq('<a target="_blank" rel="noopener noreferrer" href="https://gitlab.com">https://gitlab.com <i aria-hidden="true" data-hidden="true" class="fa fa-external-link"></i></a>')
  end

  it 'allows options when creating external link with icon' do
    expect(external_link('https://gitlab.com', 'https://gitlab.com', { "data-foo": "bar", class: "externalLink" }).to_s)
      .to eq('<a target="_blank" rel="noopener noreferrer" data-foo="bar" class="externalLink" href="https://gitlab.com">https://gitlab.com <i aria-hidden="true" data-hidden="true" class="fa fa-external-link"></i></a>')
  end
end
