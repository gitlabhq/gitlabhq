# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Experience level screen' do
  let_it_be(:user) { create(:user, :unconfirmed) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_owner(user)
    gitlab_sign_in(user)
    visit users_sign_up_experience_level_path(namespace_path: group.to_param)
  end

  subject { page }

  it 'shows the intro content' do
    is_expected.to have_content('Hello there')
    is_expected.to have_content('Welcome to the guided GitLab tour')
    is_expected.to have_content('What describes you best?')
  end

  it 'shows the option for novice' do
    is_expected.to have_content('Novice')
    is_expected.to have_content('I’m not familiar with the basics of DevOps')
    is_expected.to have_content('Show me the basics')
  end

  it 'shows the option for experienced' do
    is_expected.to have_content('Experienced')
    is_expected.to have_content('I’m familiar with the basics of DevOps')
    is_expected.to have_content('Show me advanced features')
  end

  it 'does not display any flash messages' do
    is_expected.not_to have_selector('.flash-container')
    is_expected.not_to have_content("Please check your email (#{user.email}) to verify that you own this address and unlock the power of CI/CD")
  end

  it 'does not include the footer links' do
    is_expected.not_to have_link('Help')
    is_expected.not_to have_link('About GitLab')
  end
end
