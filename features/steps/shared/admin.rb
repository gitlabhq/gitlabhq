module SharedAdmin
  include Spinach::DSL

  step 'there are projects in system' do
    2.times { create(:project, :repository) }
  end

  step 'system has users' do
    2.times { create(:user) }
  end
end
