require 'spec_helper'

describe Dashboard::ProjectsController do
  it_behaves_like 'authenticates sessionless user', :index, :atom
end
