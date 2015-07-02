module SharedAdmin
  include Spinach::DSL

  step 'there are projects in system' do
    2.times { create(:project) }
  end

  step 'system has users' do
    2.times { create(:user) }
  end

  And 'there are groups with projects' do
    2.times do
      group = create :group
      create :project, group: group
    end
  end
end
