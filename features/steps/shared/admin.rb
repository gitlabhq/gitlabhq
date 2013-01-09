module SharedAdmin
  include Spinach::DSL

  And 'there are projects in system' do
    2.times { create(:project) }
  end

  And 'system has users' do
    2.times { create(:user) }
  end
end

