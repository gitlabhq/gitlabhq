# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['JobArtifactFileType'] do
  it 'exposes all job artifact file types' do
    expect(described_class.values.keys).to match_array(
      ::Enums::Ci::JobArtifact.type_and_format_pairs.keys.map(&:to_s).map(&:upcase)
    )
  end
end
