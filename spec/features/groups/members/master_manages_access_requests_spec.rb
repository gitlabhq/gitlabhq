require 'spec_helper'

describe 'Groups > Members > Maintainer manages access requests' do
  it_behaves_like 'Maintainer manages access requests' do
    let(:entity) { create(:group, :public, :access_requestable) }
    let(:members_page_path) { group_group_members_path(entity) }
  end
end
