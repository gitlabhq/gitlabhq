require 'spec_helper'

describe RepositoryHelper do
  let(:user) { create(:user, :admin) }
  let(:project) { create(:project, :repository) }

  before do
    project.protected_branches.create(name: 'master')
  end

  describe 'Access Level Options' do
    it 'has three push access levels' do
      push_access_levels = helper.access_levels_options[:push_access_levels]["Roles"]
      expect(push_access_levels.size).to eq(3)
    end
     
    it 'has one merge access level' do
      merge_access_levels = helper.access_levels_options[:merge_access_levels]["Roles"]
      expect(merge_access_levels.size).to eq(2)
    end
  end
end
