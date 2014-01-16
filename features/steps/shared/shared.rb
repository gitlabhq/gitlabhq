module Shared
  include Spinach::DSL

  Then 'page status code should be 404' do
    page.status_code.should == 404
  end
end
