# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen' do
  let(:user) { create(:user) }

  before do
    gitlab_sign_in(user)

    visit users_sign_up_welcome_path
  end

  it 'shows the email opt in' do
    select 'Software Developer', from: 'user_role'
    check 'user_email_opted_in'
    click_button 'Get started!'

    expect(user.reload.email_opted_in).to eq(true)
  end
end
