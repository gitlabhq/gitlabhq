require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the NavHelper. For example:
#
# describe NavHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
describe NavHelper do
  describe '#nav_menu_collapsed?' do
    it 'returns true when the nav is collapsed in the cookie' do
      helper.request.cookies[:collapsed_nav] = 'true'
      expect(helper.nav_menu_collapsed?).to eq true
    end

    it 'returns false when the nav is not collapsed in the cookie' do
      helper.request.cookies[:collapsed_nav] = 'false'
      expect(helper.nav_menu_collapsed?).to eq false
    end
  end
end
