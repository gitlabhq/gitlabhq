# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::BaseSecurityAnalyzer do
  include GraphqlHelpers

  it 'raises a NotImplementedError error if the resolve method is called on the base class' do
    user = create(:user)
    project = create(:project, :public, :repository)
    project.add_developer(user)
    expect { resolve(described_class, args: { project_path: project.full_path }, ctx: { current_user: user }) }.to raise_error(NotImplementedError)
  end
end
