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

    let_it_be(:user) { create(:user) }
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
          expect(element.attr('class')).to match('btn-sm')
          expect(element.attr('class')).to match('btn-default')
          expect(element.attr('class')).to match('btn-default-tertiary')
          expect(element.attr('title')).to eq('Copy')
          expect(element.attr('type')).to eq('button')
          expect(element.attr('aria-label')).to eq('Copy')
          expect(element.attr('aria-live')).to eq('polite')
          expect(element.attr('data-toggle')).to eq('tooltip')
          expect(element.attr('data-placement')).to eq('bottom')
          expect(element.attr('data-container')).to eq('body')
          expect(element.attr('data-clipboard-text')).to eq(nil)
          expect(element.attr('itemprop')).to eq(nil)
          expect(element.inner_text.strip).to eq('')

          expect(element.to_html).to match('svg#copy-to-clipboard')
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
        expect(element(button_text: 'Copy text').inner_text.strip).to eq('Copy text')
      end

      it 'adds `gl-button-icon` class to icon' do
        expect(element(button_text: 'Copy text')).to have_css('svg.gl-button-icon')
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
        expect(element(hide_button_icon: true).to_html).not_to match('svg#copy-to-clipboard')
      end
    end

    context 'with `itemprop` attribute provided' do
      it 'shows copy to clipboard button with `itemprop` attribute' do
        expect(element(itemprop: 'identifier').attr('itemprop')).to eq('identifier')
      end
    end

    context 'when variant option is provided' do
      it 'inherits the correct ButtonComponent class' do
        expect(element(variant: :confirm).attr('class')).to match('btn-confirm-tertiary')
      end
    end

    context 'when category option is provided' do
      it 'inherits the correct ButtonComponent class' do
        expect(element(category: :secondary).attr('class')).to match('btn-default-secondary')
      end
    end

    context 'when size option is provided' do
      it 'inherits the correct ButtonComponent class' do
        expect(element(size: :medium).attr('class')).to match('btn-md')
      end
    end
  end

  describe '#link_button_to', feature_category: :design_system do
    let(:content) { 'Button content' }
    let(:href) { '#' }
    let(:options) { {} }

    RSpec.shared_examples 'basic behavior' do
      it 'renders a basic link button' do
        expect(subject.name).to eq('a')
        expect(subject.classes).to include(*%w[gl-button btn btn-md btn-default])
        expect(subject.attr('href')).to eq(href)
        expect(subject.content.strip).to eq(content)
      end

      describe 'variant option' do
        let(:options) { { variant: :danger } }

        it 'renders the variant class' do
          expect(subject.classes).to include('btn-danger')
        end
      end

      describe 'category option' do
        let(:options) { { category: :tertiary } }

        it 'renders the category class' do
          expect(subject.classes).to include('btn-default-tertiary')
        end
      end

      describe 'size option' do
        let(:options) { { size: :small } }

        it 'renders the small class' do
          expect(subject.classes).to include('btn-sm')
        end
      end

      describe 'block option' do
        let(:options) { { block: true } }

        it 'renders the block class' do
          expect(subject.classes).to include('btn-block')
        end
      end

      describe 'selected option' do
        let(:options) { { selected: true } }

        it 'renders the selected class' do
          expect(subject.classes).to include('selected')
        end
      end

      describe 'target option' do
        let(:options) { { target: '_blank' } }

        it 'renders the target attribute' do
          expect(subject.attr('target')).to eq('_blank')
        end
      end

      describe 'method option' do
        let(:options) { { method: :post } }

        it 'renders the data-method attribute' do
          expect(subject.attr('data-method')).to eq('post')
        end
      end

      describe 'icon option' do
        let(:options) { { icon: 'remove' } }

        it 'renders the icon' do
          icon = subject.at_css('svg.gl-icon')
          expect(icon.attr('data-testid')).to eq('remove-icon')
        end
      end

      describe 'icon only' do
        let(:content) { nil }
        let(:options) { { icon: 'remove' } }

        it 'renders the icon-only class' do
          expect(subject.classes).to include('btn-icon')
        end
      end

      describe 'arbitrary html options' do
        let(:content) { nil }
        let(:options) { { data: { foo: true }, aria: { labelledby: 'foo' } } }

        it 'renders the attributes' do
          expect(subject.attr('data-foo')).to eq('true')
          expect(subject.attr('aria-labelledby')).to eq('foo')
        end
      end
    end

    describe 'without block' do
      subject do
        tag = helper.link_button_to content, href, options
        Nokogiri::HTML.fragment(tag).first_element_child
      end

      include_examples 'basic behavior'
    end

    describe 'with block' do
      subject do
        tag = helper.link_button_to href, options do
          content
        end
        Nokogiri::HTML.fragment(tag).first_element_child
      end

      include_examples 'basic behavior'
    end
  end
end
