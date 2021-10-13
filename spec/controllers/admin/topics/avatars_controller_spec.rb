# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Topics::AvatarsController do
  let(:user) { create(:admin) }
  let(:topic) { create(:topic, avatar: fixture_file_upload("spec/fixtures/dk.png")) }

  before do
    sign_in(user)
    controller.instance_variable_set(:@topic, topic)
  end

  it 'removes avatar from DB by calling destroy' do
    delete :destroy, params: { topic_id: topic.id }
    @topic = assigns(:topic)
    expect(@topic.avatar.present?).to be_falsey
    expect(@topic).to be_valid
  end
end
