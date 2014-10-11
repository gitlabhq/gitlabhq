require 'spec_helper'

describe UsersFinder do
  before do
    @user = create :user
    @admin = create :user, admin: true
    @blocked = create :user, state: :blocked
  end

  it { UsersFinder.new.execute("admins").should == [@admin] }
  it { UsersFinder.new.execute("blocked").should == [@blocked] }
  it { UsersFinder.new.execute("wop").should include(@user, @admin, @blocked) }
  it { UsersFinder.new.execute(nil).should include(@user, @admin) }
end
