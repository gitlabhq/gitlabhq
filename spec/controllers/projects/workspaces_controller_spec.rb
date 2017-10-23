require 'spec_helper'

describe Projects::WorkspacesController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:environment) { create(:environment, name: 'production', project: project) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end
end
