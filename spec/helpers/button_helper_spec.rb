# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ButtonHelper do
  describe 'http_clone_button' do
    let(:user) { create(:user) }
    let(:project) { build_stubbed(:project) }
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

        it 'shows the password text on the dropdown' do
          description = element.search('.dropdown-menu-inner-content').first

          expect(description.inner_text).to eq 'Set a password on your account to pull or push via HTTP.'
        end
      end
    end

    context 'with internal auth disabled' do
      before do
        stub_application_setting(password_authentication_enabled_for_git?: false)
      end

      context 'when user has no personal access tokens' do
        it 'has a personal access token text on the dropdown description' do
          description = element.search('.dropdown-menu-inner-content').first

          expect(description.inner_text).to eq 'Create a personal access token on your account to pull or push via HTTP.'
        end
      end

      context 'when user has personal access tokens' do
        before do
          create(:personal_access_token, user: user)
        end

        it 'does not have a personal access token text on the dropdown description' do
          description = element.search('.dropdown-menu-inner-content').first

          expect(description).to be_nil
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

  describe 'ssh_button' do
    let(:user) { create(:user) }
    let(:project) { build_stubbed(:project) }

    def element
      element = helper.ssh_clone_button(project)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'without an ssh key on the user' do
      it 'shows a warning on the dropdown description' do
        description = element.search('.dropdown-menu-inner-content').first

        expect(description.inner_text).to eq "You won't be able to pull or push repositories via SSH until you add an SSH key to your profile"
      end
    end

    context 'without an ssh key on the user and user_show_add_ssh_key_message unset' do
      before do
        stub_application_setting(user_show_add_ssh_key_message: false)
      end

      it 'there is no warning on the dropdown description' do
        description = element.search('.dropdown-menu-inner-content').first

        expect(description).to be_nil
      end
    end

    context 'with an ssh key on the user' do
      before do
        create(:key, user: user)
      end

      it 'there is no warning on the dropdown description' do
        description = element.search('.dropdown-menu-inner-content').first

        expect(description).to eq nil
      end
    end
  end

  describe 'ssh and http clone buttons' do
    let(:user) { create(:user) }
    let(:project) { build_stubbed(:project) }

    def http_button_element
      element = helper.http_clone_button(project, append_link: false)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    def ssh_button_element
      element = helper.ssh_clone_button(project, append_link: false)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'only shows the title of any of the clone buttons when append_link is false' do
      expect(http_button_element.text).to eq('HTTP')
      expect(http_button_element.search('.dropdown-menu-inner-content').first).to eq(nil)
      expect(ssh_button_element.text).to eq('SSH')
      expect(ssh_button_element.search('.dropdown-menu-inner-content').first).to eq(nil)
    end
  end

  describe 'clipboard_button' do
    include IconsHelper

    let(:user) { create(:user) }
    let(:project) { build_stubbed(:project) }

    def element(data = {})
      element = helper.clipboard_button(data)
      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'with default options' do
      context 'when no `text` attribute is not provided' do
        it 'shows copy to clipboard button with default configuration and no text set to copy' do
          expect(element.attr('class')).to eq('btn btn-clipboard btn-transparent')
          expect(element.attr('type')).to eq('button')
          expect(element.attr('aria-label')).to eq('Copy')
          expect(element.attr('data-toggle')).to eq('tooltip')
          expect(element.attr('data-placement')).to eq('bottom')
          expect(element.attr('data-container')).to eq('body')
          expect(element.attr('data-clipboard-text')).to eq(nil)
          expect(element.attr('itemprop')).to eq(nil)
          expect(element.inner_text).to eq("")

          expect(element.to_html).to include sprite_icon('copy-to-clipboard')
        end
      end

      context 'when `text` attribute is provided' do
        it 'shows copy to clipboard button with provided `text` to copy' do
          expect(element(text: 'Hello World!').attr('data-clipboard-text')).to eq('Hello World!')
        end
      end

      context 'when `title` attribute is provided' do
        it 'shows copy to clipboard button with provided `title` as tooltip' do
          expect(element(title: 'Copy to my clipboard!').attr('aria-label')).to eq('Copy to my clipboard!')
        end
      end
    end

    context 'with `button_text` attribute provided' do
      it 'shows copy to clipboard button with provided `button_text` as button label' do
        expect(element(button_text: 'Copy text').inner_text).to eq('Copy text')
      end
    end

    context 'with `hide_tooltip` attribute provided' do
      it 'shows copy to clipboard button without tooltip support' do
        expect(element(hide_tooltip: true).attr('data-placement')).to eq(nil)
        expect(element(hide_tooltip: true).attr('data-toggle')).to eq(nil)
        expect(element(hide_tooltip: true).attr('data-container')).to eq(nil)
      end
    end

    context 'with `hide_button_icon` attribute provided' do
      it 'shows copy to clipboard button without tooltip support' do
        expect(element(hide_button_icon: true).to_html).not_to include sprite_icon('duplicate')
      end
    end

    context 'with `itemprop` attribute provided' do
      it 'shows copy to clipboard button with `itemprop` attribute' do
        expect(element(itemprop: "identifier").attr('itemprop')).to eq("identifier")
      end
    end
  end
end
