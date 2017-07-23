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
      is_expected.to eq image_tag(
        avatar_icon(user, 16),
        class: 'avatar has-tooltip s16 ',
        alt: "#{user.name}'s avatar",
        title: user.name,
        data: { container: 'body' }
      )
    end

    context 'with css_class parameter' do
      let(:options) { { user: user, css_class: '.cat-pics' } }

      it 'uses provided css_class' do
        is_expected.to eq image_tag(
          avatar_icon(user, 16),
          class: "avatar has-tooltip s16 #{options[:css_class]}",
          alt: "#{user.name}'s avatar",
          title: user.name,
          data: { container: 'body' }
        )
      end
    end

    context 'with lazy parameter' do
      let(:options) { { user: user, lazy: true } }

      it 'uses data-src instead of src' do
        is_expected.to eq image_tag(
          '',
          class: 'avatar has-tooltip s16 ',
          alt: "#{user.name}'s avatar",
          title: user.name,
          data: { container: 'body', src: avatar_icon(user, 16) }
        )
      end
    end

    context 'with size parameter' do
      let(:options) { { user: user, size: 99 } }

      it 'uses provided size' do
        is_expected.to eq image_tag(
          avatar_icon(user, options[:size]),
          class: "avatar has-tooltip s#{options[:size]} ",
          alt: "#{user.name}'s avatar",
          title: user.name,
          data: { container: 'body' }
        )
      end
    end

    context 'with url parameter' do
      let(:options) { { user: user, url: '/over/the/rainbow.png' } }

      it 'uses provided url' do
        is_expected.to eq image_tag(
          options[:url],
          class: 'avatar has-tooltip s16 ',
          alt: "#{user.name}'s avatar",
          title: user.name,
          data: { container: 'body' }
        )
      end
    end

    context 'with user_name parameter' do
      let(:options) { { user_name: 'Tinky Winky', user_email: 'no@f.un' } }

      context 'with user parameter' do
        let(:options) { { user: user, user_name: 'Tinky Winky' } }

        it 'prefers user parameter' do
          is_expected.to eq image_tag(
            avatar_icon(user, 16),
            class: 'avatar has-tooltip s16 ',
            alt: "#{user.name}'s avatar",
            title: user.name,
            data: { container: 'body' }
          )
        end
      end

      it 'uses user_name and user_email parameter if user is not present' do
        is_expected.to eq image_tag(
          avatar_icon(options[:user_email], 16),
          class: 'avatar has-tooltip s16 ',
          alt: "#{options[:user_name]}'s avatar",
          title: options[:user_name],
          data: { container: 'body' }
        )
      end
    end
  end
end
