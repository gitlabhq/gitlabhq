module QA
  feature 'create a branch', :core do
    scenario 'user creates a branch' do
      Scenario::Gitlab::Project::Repository::Branch::Create.perform do |branch|
        branch.ref = 'master'
        branch.name = 'awesome-branch'
      end

      expect(page).to have_content(/awesome-branch/)
    end
  end
end
