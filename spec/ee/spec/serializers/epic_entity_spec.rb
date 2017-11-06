require 'spec_helper'

describe EpicEntity do
  let(:group)  { create(:group) }
  let(:resource) { create(:epic, group: group) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'has Issuable attributes' do
    expect(subject).to include(:id, :iid, :author_id, :description, :lock_version, :milestone_id,
                               :title, :updated_by_id, :created_at, :updated_at, :milestone, :labels)
  end

  it 'has epic specific attributes' do
    expect(subject).to include(:start_date, :end_date, :group_id, :web_url)
  end
end
