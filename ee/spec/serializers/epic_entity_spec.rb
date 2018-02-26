require 'spec_helper'

describe EpicEntity do
  let(:group)  { create(:group) }
  let(:resource) { create(:epic, group: group) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'has Issuable attributes' do
    expect(subject).to include(:id, :iid, :description,  :title, :labels)
  end

  it 'has epic specific attributes' do
    expect(subject).to include(:start_date, :end_date, :group_id, :group_name, :group_full_name, :web_url)
  end
end
