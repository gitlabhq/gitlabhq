require 'spec_helper'

describe SearchController do
  let(:project) { create(:project, public: true) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#find_project_ids' do
    it 'should include public projects ids when searching within a single project' do
      project_ids = controller.send(:find_project_ids,nil, project.id)
      project_ids.size.should == 1
      project_ids[0].should == project.id
    end
  end
end
