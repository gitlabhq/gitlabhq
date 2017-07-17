require 'spec_helper'

describe ButtonHelper do
  describe 'http_clone_button' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:has_tooltip_class) { 'has-tooltip' }

    def element
      element = helper.http_clone_button(project)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'with internal auth enabled' do
      context 'when user has a password' do
        it 'shows no tooltip' do
          expect(element.attr('class')).not_to include(has_tooltip_class)
        end
      end

      context 'when user has password automatically set' do
        let(:user) { create(:user, password_automatically_set: true) }

        it 'shows a password tooltip' do
          expect(element.attr('class')).to include(has_tooltip_class)
          expect(element.attr('data-title')).to eq('Set a password on your account to pull or push via HTTP.')
        end
      end
    end

    context 'with internal auth disabled' do
      before do
        stub_application_setting(password_authentication_enabled?: false)
      end

      context 'when user has no personal access tokens' do
        it 'has a personal access token tooltip ' do
          expect(element.attr('class')).to include(has_tooltip_class)
          expect(element.attr('data-title')).to eq('Create a personal access token on your account to pull or push via HTTP.')
        end
      end

      context 'when user has a personal access token' do
        it 'shows no tooltip' do
          create(:personal_access_token, user: user)

          expect(element.attr('class')).not_to include(has_tooltip_class)
        end
      end
    end

    context 'when user is ldap user' do
      let(:user) { create(:omniauth_user, password_automatically_set: true) }

      it 'shows no tooltip' do
        expect(element.attr('class')).not_to include(has_tooltip_class)
      end
    end
  end
end
