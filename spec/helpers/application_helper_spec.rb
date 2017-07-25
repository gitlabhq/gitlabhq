# coding: utf-8
require 'spec_helper'

describe ApplicationHelper do
  include UploadHelpers

  let(:gitlab_host) { "http://#{Gitlab.config.gitlab.host}" }

  describe 'current_controller?' do
    it 'returns true when controller matches argument' do
      stub_controller_name('foo')

      expect(helper.current_controller?(:foo)).to eq true
    end

    it 'returns false when controller does not match argument' do
      stub_controller_name('foo')

      expect(helper.current_controller?(:bar)).to eq false
    end

    it 'takes any number of arguments' do
      stub_controller_name('foo')

      expect(helper.current_controller?(:baz, :bar)).to eq false
      expect(helper.current_controller?(:baz, :bar, :foo)).to eq true
    end

    def stub_controller_name(value)
      allow(helper.controller).to receive(:controller_name).and_return(value)
    end
  end

  describe 'current_action?' do
    it 'returns true when action matches' do
      stub_action_name('foo')

      expect(helper.current_action?(:foo)).to eq true
    end

    it 'returns false when action does not match' do
      stub_action_name('foo')

      expect(helper.current_action?(:bar)).to eq false
    end

    it 'takes any number of arguments' do
      stub_action_name('foo')

      expect(helper.current_action?(:baz, :bar)).to eq false
      expect(helper.current_action?(:baz, :bar, :foo)).to eq true
    end

    def stub_action_name(value)
      allow(helper).to receive(:action_name).and_return(value)
    end
  end

  describe 'project_icon' do
    it 'returns an url for the avatar' do
      project = create(:empty_project, avatar: File.open(uploaded_image_temp_path))
      avatar_url = "/uploads/-/system/project/avatar/#{project.id}/banana_sample.gif"

      expect(helper.project_icon(project.full_path).to_s)
        .to eq "<img data-src=\"#{avatar_url}\" class=\" lazy\" src=\"#{LazyImageTagHelper.placeholder_image}\" />"

      allow(ActionController::Base).to receive(:asset_host).and_return(gitlab_host)
      avatar_url = "#{gitlab_host}/uploads/-/system/project/avatar/#{project.id}/banana_sample.gif"

      expect(helper.project_icon(project.full_path).to_s)
        .to eq "<img data-src=\"#{avatar_url}\" class=\" lazy\" src=\"#{LazyImageTagHelper.placeholder_image}\" />"
    end

    it 'gives uploaded icon when present' do
      project = create(:empty_project)

      allow_any_instance_of(Project).to receive(:avatar_in_git).and_return(true)

      avatar_url = "#{gitlab_host}#{project_avatar_path(project)}"
      expect(helper.project_icon(project.full_path).to_s)
        .to eq "<img data-src=\"#{avatar_url}\" class=\" lazy\" src=\"#{LazyImageTagHelper.placeholder_image}\" />"
    end
  end

  describe 'avatar_icon' do
    let(:user) { create(:user, avatar: File.open(uploaded_image_temp_path)) }

    context 'using an email' do
      context 'when there is a matching user' do
        it 'returns a relative URL for the avatar' do
          expect(helper.avatar_icon(user.email).to_s)
            .to eq("/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif")
        end

        context 'when an asset_host is set in the config' do
          let(:asset_host) { 'http://assets' }

          before do
            allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
          end

          it 'returns an absolute URL on that asset host' do
            expect(helper.avatar_icon(user.email, only_path: false).to_s)
              .to eq("#{asset_host}/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif")
          end
        end

        context 'when only_path is set to false' do
          it 'returns an absolute URL for the avatar' do
            expect(helper.avatar_icon(user.email, only_path: false).to_s)
              .to eq("#{gitlab_host}/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif")
          end
        end

        context 'when the GitLab instance is at a relative URL' do
          before do
            stub_config_setting(relative_url_root: '/gitlab')
            # Must be stubbed after the stub above, and separately
            stub_config_setting(url: Settings.send(:build_gitlab_url))
          end

          it 'returns a relative URL with the correct prefix' do
            expect(helper.avatar_icon(user.email).to_s)
              .to eq("/gitlab/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif")
          end
        end
      end

      context 'when no user exists for the email' do
        it 'calls gravatar_icon' do
          expect(helper).to receive(:gravatar_icon).with('foo@example.com', 20, 2)

          helper.avatar_icon('foo@example.com', 20, 2)
        end
      end
    end

    describe 'using a user' do
      context 'when only_path is true' do
        it 'returns a relative URL for the avatar' do
          expect(helper.avatar_icon(user, only_path: true).to_s)
            .to eq("/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif")
        end
      end

      context 'when only_path is false' do
        it 'returns an absolute URL for the avatar' do
          expect(helper.avatar_icon(user, only_path: false).to_s)
            .to eq("#{gitlab_host}/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif")
        end
      end
    end
  end

  describe 'gravatar_icon' do
    let(:user_email) { 'user@email.com' }

    context 'with Gravatar disabled' do
      before do
        stub_application_setting(gravatar_enabled?: false)
      end

      it 'returns a generic avatar' do
        expect(helper.gravatar_icon(user_email)).to match('no_avatar.png')
      end
    end

    context 'with Gravatar enabled' do
      before do
        stub_application_setting(gravatar_enabled?: true)
      end

      it 'returns a generic avatar when email is blank' do
        expect(helper.gravatar_icon('')).to match('no_avatar.png')
      end

      it 'returns a valid Gravatar URL' do
        stub_config_setting(https: false)

        expect(helper.gravatar_icon(user_email))
          .to match('http://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118')
      end

      it 'uses HTTPs when configured' do
        stub_config_setting(https: true)

        expect(helper.gravatar_icon(user_email))
          .to match('https://secure.gravatar.com')
      end

      it 'returns custom gravatar path when gravatar_url is set' do
        stub_gravatar_setting(plain_url: 'http://example.local/?s=%{size}&hash=%{hash}')

        expect(gravatar_icon(user_email, 20))
          .to eq('http://example.local/?s=40&hash=b58c6f14d292556214bd64909bcdb118')
      end

      it 'accepts a custom size argument' do
        expect(helper.gravatar_icon(user_email, 64)).to include '?s=128'
      end

      it 'defaults size to 40@2x when given an invalid size' do
        expect(helper.gravatar_icon(user_email, nil)).to include '?s=80'
      end

      it 'accepts a scaling factor' do
        expect(helper.gravatar_icon(user_email, 40, 3)).to include '?s=120'
      end

      it 'ignores case and surrounding whitespace' do
        normal = helper.gravatar_icon('foo@example.com')
        upcase = helper.gravatar_icon(' FOO@EXAMPLE.COM ')

        expect(normal).to eq upcase
      end
    end
  end

  describe 'simple_sanitize' do
    let(:a_tag) { '<a href="#">Foo</a>' }

    it 'allows the a tag' do
      expect(helper.simple_sanitize(a_tag)).to eq(a_tag)
    end

    it 'allows the span tag' do
      input = '<span class="foo">Bar</span>'
      expect(helper.simple_sanitize(input)).to eq(input)
    end

    it 'disallows other tags' do
      input = "<strike><b>#{a_tag}</b></strike>"
      expect(helper.simple_sanitize(input)).to eq(a_tag)
    end
  end

  describe 'time_ago_with_tooltip' do
    def element(*arguments)
      Time.zone = 'UTC'
      @time = Time.zone.parse('2015-07-02 08:23')
      element = helper.time_ago_with_tooltip(@time, *arguments)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    it 'returns a time element' do
      expect(element.name).to eq 'time'
    end

    it 'includes the date string' do
      expect(element.text).to eq @time.strftime("%b %d, %Y")
    end

    it 'has a datetime attribute' do
      expect(element.attr('datetime')).to eq '2015-07-02T08:23:00Z'
    end

    it 'has a formatted title attribute' do
      expect(element.attr('title')).to eq 'Jul 2, 2015 8:23am'
    end

    it 'includes a default js-timeago class' do
      expect(element.attr('class')).to eq 'js-timeago'
    end

    it 'accepts a custom html_class' do
      expect(element(html_class: 'custom_class').attr('class'))
        .to eq 'js-timeago custom_class'
    end

    it 'accepts a custom tooltip placement' do
      expect(element(placement: 'bottom').attr('data-placement')).to eq 'bottom'
    end

    it 'converts to Time' do
      expect { helper.time_ago_with_tooltip(Date.today) }.not_to raise_error
    end

    it 'add class for the short format' do
      timeago_element = element(short_format: 'short')
      expect(timeago_element.attr('class')).to eq 'js-short-timeago'
      expect(timeago_element.next_element).to eq nil
    end
  end

  describe '#active_when' do
    it { expect(helper.active_when(true)).to eq('active') }
    it { expect(helper.active_when(false)).to eq(nil) }
  end

  describe '#support_url' do
    context 'when alternate support url is specified' do
      let(:alternate_url) { 'http://company.example.com/getting-help' }

      before do
        stub_application_setting(help_page_support_url: alternate_url)
      end

      it 'returns the alternate support url' do
        expect(helper.support_url).to eq(alternate_url)
      end
    end

    context 'when alternate support url is not specified' do
      it 'builds the support url from the promo_url' do
        expect(helper.support_url).to eq(helper.promo_url + '/getting-help/')
      end
    end
  end
end
