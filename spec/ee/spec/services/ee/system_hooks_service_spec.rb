require 'spec_helper'

describe EE::SystemHooksService do
  let(:user) { create(:user) }

  context 'event data' do
    it { expect(event_data(user, :create)).to include(:event_name, :name, :created_at, :updated_at, :email, :user_id, :username, :email_opted_in) }
    it { expect(event_data(user, :destroy)).to include(:event_name, :name, :created_at, :updated_at, :email, :user_id, :username, :email_opted_in) }
  end

  def event_data(*args)
    SystemHooksService.new.send :build_event_data, *args
  end
end
