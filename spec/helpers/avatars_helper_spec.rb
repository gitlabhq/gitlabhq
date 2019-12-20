# frozen_string_literal: true

require 'spec_helper'

describe AvatarsHelper do
  include UploadHelpers

  let(:user) { create(:user) }

  describe '#project_icon & #group_icon' do
    shared_examples 'resource with a default avatar' do |source_type|
      it 'returns a default avatar div' do
        expect(public_send("#{source_type}_icon", *helper_args))
          .to match(%r{<div class="identicon bg\d+">F</div>})
      end
    end

    shared_examples 'resource with a custom avatar' do |source_type|
      it 'returns a custom avatar image' do
        expect(public_send("#{source_type}_icon", *helper_args))
          .to eq "<img src=\"#{resource.avatar.url}\" />"
      end
    end

    context 'when providing a project' do
      it_behaves_like 'resource with a default avatar', 'project' do
        let(:resource) { create(:project, name: 'foo') }
        let(:helper_args) { [resource] }
      end

      it_behaves_like 'resource with a custom avatar', 'project' do
        let(:resource) { create(:project, :public, avatar: File.open(uploaded_image_temp_path)) }
        let(:helper_args) { [resource] }
      end
    end

    context 'when providing a group' do
      it_behaves_like 'resource with a default avatar', 'group' do
        let(:resource) { create(:group, name: 'foo') }
        let(:helper_args) { [resource] }
      end

      it_behaves_like 'resource with a custom avatar', 'group' do
        let(:resource) { create(:group, avatar: File.open(uploaded_image_temp_path)) }
        let(:helper_args) { [resource] }
      end
    end
  end

  describe '#avatar_icon_for' do
    let!(:user) { create(:user, avatar: File.open(uploaded_image_temp_path), email: 'bar@example.com') }
    let(:email) { 'foo@example.com' }
    let!(:another_user) { create(:user, avatar: File.open(uploaded_image_temp_path), email: email) }

    it 'prefers the user to retrieve the avatar_url' do
      expect(helper.avatar_icon_for(user, email).to_s)
        .to eq(user.avatar.url)
    end

    it 'falls back to email lookup if no user given' do
      expect(helper.avatar_icon_for(nil, email).to_s)
        .to eq(another_user.avatar.url)
    end
  end

  describe '#avatar_icon_for_email' do
    let(:user) { create(:user, avatar: File.open(uploaded_image_temp_path)) }

    context 'using an email' do
      context 'when there is a matching user' do
        it 'returns a relative URL for the avatar' do
          expect(helper.avatar_icon_for_email(user.email).to_s)
            .to eq(user.avatar.url)
        end
      end

      context 'when no user exists for the email' do
        it 'calls gravatar_icon' do
          expect(helper).to receive(:gravatar_icon).with('foo@example.com', 20, 2)

          helper.avatar_icon_for_email('foo@example.com', 20, 2)
        end
      end

      context 'without an email passed' do
        it 'calls gravatar_icon' do
          expect(helper).to receive(:gravatar_icon).with(nil, 20, 2)

          helper.avatar_icon_for_email(nil, 20, 2)
        end
      end
    end
  end

  describe '#avatar_icon_for_user' do
    let(:user) { create(:user, avatar: File.open(uploaded_image_temp_path)) }

    context 'with a user object passed' do
      it 'returns a relative URL for the avatar' do
        expect(helper.avatar_icon_for_user(user).to_s)
          .to eq(user.avatar.url)
      end
    end

    context 'without a user object passed' do
      it 'calls gravatar_icon' do
        expect(helper).to receive(:gravatar_icon).with(nil, 20, 2)

        helper.avatar_icon_for_user(nil, 20, 2)
      end
    end
  end

  describe '#gravatar_icon' do
    let(:user_email) { 'user@email.com' }

    context 'with Gravatar disabled' do
      before do
        stub_application_setting(gravatar_enabled?: false)
      end

      it 'returns a generic avatar' do
        expect(helper.gravatar_icon(user_email)).to match_asset_path('no_avatar.png')
      end
    end

    context 'with Gravatar enabled' do
      before do
        stub_application_setting(gravatar_enabled?: true)
      end

      it 'returns a generic avatar when email is blank' do
        expect(helper.gravatar_icon('')).to match_asset_path('no_avatar.png')
      end

      it 'returns a valid Gravatar URL' do
        stub_config_setting(https: false)

        expect(helper.gravatar_icon(user_email))
          .to match('https://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118')
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

  describe '#user_avatar' do
    subject { helper.user_avatar(user: user) }

    it "links to the user's profile" do
      is_expected.to include("href=\"#{user_path(user)}\"")
    end

    it "has the user's name as title" do
      is_expected.to include("title=\"#{user.name}\"")
    end

    it "contains the user's avatar image" do
      is_expected.to include(CGI.escapeHTML(user.avatar_url(size: 16)))
    end
  end

  describe '#user_avatar_without_link' do
    let(:options) { { user: user } }

    subject { helper.user_avatar_without_link(options) }

    it 'displays user avatar' do
      is_expected.to eq tag(
        :img,
        alt: "#{user.name}'s avatar",
        src: avatar_icon_for_user(user, 16),
        data: { container: 'body' },
        class: 'avatar s16 has-tooltip',
        title: user.name
      )
    end

    context 'with css_class parameter' do
      let(:options) { { user: user, css_class: '.cat-pics' } }

      it 'uses provided css_class' do
        is_expected.to eq tag(
          :img,
          alt: "#{user.name}'s avatar",
          src: avatar_icon_for_user(user, 16),
          data: { container: 'body' },
          class: "avatar s16 #{options[:css_class]} has-tooltip",
          title: user.name
        )
      end
    end

    context 'with size parameter' do
      let(:options) { { user: user, size: 99 } }

      it 'uses provided size' do
        is_expected.to eq tag(
          :img,
          alt: "#{user.name}'s avatar",
          src: avatar_icon_for_user(user, options[:size]),
          data: { container: 'body' },
          class: "avatar s#{options[:size]} has-tooltip",
          title: user.name
        )
      end
    end

    context 'with url parameter' do
      let(:options) { { user: user, url: '/over/the/rainbow.png' } }

      it 'uses provided url' do
        is_expected.to eq tag(
          :img,
          alt: "#{user.name}'s avatar",
          src: options[:url],
          data: { container: 'body' },
          class: "avatar s16 has-tooltip",
          title: user.name
        )
      end
    end

    context 'with lazy parameter' do
      let(:options) { { user: user, lazy: true } }

      it 'adds `lazy` class to class list, sets `data-src` with avatar URL and `src` with placeholder image' do
        is_expected.to eq tag(
          :img,
          alt: "#{user.name}'s avatar",
          src: LazyImageTagHelper.placeholder_image,
          data: { container: 'body', src: avatar_icon_for_user(user, 16) },
          class: "avatar s16 has-tooltip lazy",
          title: user.name
        )
      end
    end

    context 'with has_tooltip parameter' do
      context 'with has_tooltip set to true' do
        let(:options) { { user: user, has_tooltip: true } }

        it 'adds has-tooltip' do
          is_expected.to eq tag(
            :img,
            alt: "#{user.name}'s avatar",
            src: avatar_icon_for_user(user, 16),
            data: { container: 'body' },
            class: "avatar s16 has-tooltip",
            title: user.name
          )
        end
      end

      context 'with has_tooltip set to false' do
        let(:options) { { user: user, has_tooltip: false } }

        it 'does not add has-tooltip or data container' do
          is_expected.to eq tag(
            :img,
            alt: "#{user.name}'s avatar",
            src: avatar_icon_for_user(user, 16),
            class: "avatar s16",
            title: user.name
          )
        end
      end
    end

    context 'with user_name parameter' do
      let(:options) { { user_name: 'Tinky Winky', user_email: 'no@f.un' } }

      context 'with user parameter' do
        let(:options) { { user: user, user_name: 'Tinky Winky' } }

        it 'prefers user parameter' do
          is_expected.to eq tag(
            :img,
            alt: "#{user.name}'s avatar",
            src: avatar_icon_for_user(user, 16),
            data: { container: 'body' },
            class: "avatar s16 has-tooltip",
            title: user.name
          )
        end
      end

      it 'uses user_name and user_email parameter if user is not present' do
        is_expected.to eq tag(
          :img,
          alt: "#{options[:user_name]}'s avatar",
          src: avatar_icon_for_email(options[:user_email], 16),
          data: { container: 'body' },
          class: "avatar s16 has-tooltip",
          title: options[:user_name]
        )
      end
    end

    context 'with only_path parameter set to false' do
      let(:user_with_avatar) { create(:user, :with_avatar, username: 'foobar') }

      context 'with user parameter' do
        let(:options) { { user: user_with_avatar, only_path: false } }

        it 'will return avatar with a full path' do
          is_expected.to eq tag(
            :img,
            alt: "#{user_with_avatar.name}'s avatar",
            src: avatar_icon_for_user(user_with_avatar, 16, only_path: false),
            data: { container: 'body' },
            class: "avatar s16 has-tooltip",
            title: user_with_avatar.name
          )
        end
      end

      context 'with user_name and user_email' do
        let(:options) { { user_email: user_with_avatar.email, user_name: user_with_avatar.username, only_path: false } }

        it 'will return avatar with a full path' do
          is_expected.to eq tag(
            :img,
            alt: "#{user_with_avatar.username}'s avatar",
            src: avatar_icon_for_email(user_with_avatar.email, 16, only_path: false),
            data: { container: 'body' },
            class: "avatar s16 has-tooltip",
            title: user_with_avatar.username
          )
        end
      end
    end

    context 'with unregistered email address' do
      let(:options) { { user_email: "unregistered_email@example.com" } }

      it 'will return default alt text for avatar' do
        expect(subject).to include("default avatar")
      end
    end
  end
end
