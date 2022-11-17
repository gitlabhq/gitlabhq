# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::BaseSecurityAnalyzer do
  include GraphqlHelpers

  it 'raises a NotImplementedError error if the resolve method is called on the base class' do
    user = create(:user)
    mutation = described_class.new(context: { current_user: user }, object: nil, field: nil)
    project = create(:project, :public, :repository)
    project.add_developer(user)

    expect { mutation.resolve(project_path: project.full_path) }.to raise_error(NotImplementedError)
  end
end
