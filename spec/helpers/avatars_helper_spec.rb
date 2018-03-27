require 'rails_helper'

describe AvatarsHelper do
  include ApplicationHelper

  let(:user) { create(:user) }

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
  end
end
