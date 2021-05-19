# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PageLayoutHelper do
  describe 'page_description' do
    it 'defaults to nil' do
      expect(helper.page_description).to eq nil
    end

    it 'returns the last-pushed description' do
      helper.page_description('Foo')
      helper.page_description('Bar')
      helper.page_description('Baz')

      expect(helper.page_description).to eq 'Baz'
    end

    it 'squishes multiple newlines' do
      helper.page_description("Foo\nBar\nBaz")

      expect(helper.page_description).to eq 'Foo Bar Baz'
    end

    it 'truncates' do
      helper.page_description <<-LOREM.strip_heredoc
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
        ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
        dis parturient montes, nascetur ridiculus mus. Donec quam felis,
        ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa
        quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget,
        arcu.
      LOREM

      expect(helper.page_description).to end_with 'quam felis,...'
    end

    it 'sanitizes all HTML' do
      helper.page_description("<b>Bold</b> <h1>Header</h1>")

      expect(helper.page_description).to eq 'Bold Header'
    end

    it 'truncates before sanitizing' do
      helper.page_description('<b>Bold</b> <img> <img> <img> <h1>Header</h1> ' * 10)

      # 12 words because <img> was counted as a word
      expect(helper.page_description)
        .to eq('Bold    Header Bold    Header Bold    Header Bold    Header Bold    Header Bold    Header...')
    end
  end

  describe 'page_image' do
    it 'defaults to the GitLab logo' do
      expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
    end

    %w(project user group).each do |type|
      let(:object) { build(type, trait) }
      let(:trait) { :with_avatar }

      context "with @#{type} assigned" do
        before do
          assign(type, object)
        end

        it "uses #{type.titlecase} avatar full url" do
          expect(helper.page_image).to eq object.avatar_url(only_path: false)
        end

        context 'when avatar_url is nil' do
          let(:trait) { nil }

          it 'falls back to the default when avatar_url is nil' do
            expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
          end
        end
      end

      context "with no assignments" do
        it 'falls back to the default' do
          expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
        end
      end
    end
  end

  describe 'page_card_attributes' do
    it 'raises ArgumentError when given more than two attributes' do
      map = { foo: 'foo', bar: 'bar', baz: 'baz' }

      expect { helper.page_card_attributes(map) }
        .to raise_error(ArgumentError, /more than two attributes/)
    end

    it 'rejects blank values' do
      map = { foo: 'foo', bar: '' }
      helper.page_card_attributes(map)

      expect(helper.page_card_attributes).to eq({ foo: 'foo' })
    end
  end

  describe 'page_card_meta_tags' do
    it 'returns the twitter:label and twitter:data tags' do
      allow(helper).to receive(:page_card_attributes).and_return(foo: 'bar')

      tags = helper.page_card_meta_tags

      aggregate_failures do
        expect(tags).to include %q(<meta property="twitter:label1" content="foo" />)
        expect(tags).to include %q(<meta property="twitter:data1" content="bar" />)
      end
    end

    it 'escapes content' do
      allow(helper).to receive(:page_card_attributes)
        .and_return(foo: %q{foo" http-equiv="refresh}.html_safe)

      tags = helper.page_card_meta_tags

      expect(tags).to include(%q{content="foo&quot; http-equiv=&quot;refresh"})
    end
  end

  describe '#search_context' do
    subject(:search_context) { helper.search_context }

    describe 'a bare controller' do
      it 'returns an empty context' do
        expect(search_context).to have_attributes(project: nil,
                                                  group: nil,
                                                  snippets: [],
                                                  project_metadata: {},
                                                  group_metadata: {},
                                                  search_url: '/search')
      end
    end
  end

  describe '#page_canonical_link' do
    let(:user) { build(:user) }

    subject { helper.page_canonical_link(link) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when link is passed' do
      let(:link) { 'https://gitlab.com' }

      it 'stores and returns the link value' do
        expect(subject).to eq link
        expect(helper.page_canonical_link(nil)).to eq link
      end
    end

    context 'when no link is provided' do
      let(:link) { nil }
      let(:request) { ActionDispatch::Request.new(env) }
      let(:env) do
        {
          'ORIGINAL_FULLPATH' => '/foo/',
          'PATH_INFO' => '/foo',
          'HTTP_HOST' => 'test.host',
          'REQUEST_METHOD' => method,
          'rack.url_scheme' => 'http'
        }
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      shared_examples 'generates the canonical url using the params in the context' do
        specify { expect(subject).to eq 'http://test.host/foo' }
      end

      shared_examples 'does not return a canonical url' do
        specify { expect(subject).to be_nil }
      end

      it_behaves_like 'generates the canonical url using the params in the context' do
        let(:method) { 'GET' }
      end

      it_behaves_like 'generates the canonical url using the params in the context' do
        let(:method) { 'HEAD' }
      end

      it_behaves_like 'does not return a canonical url' do
        let(:method) { 'POST' }
      end

      it_behaves_like 'does not return a canonical url' do
        let(:method) { 'PUT' }
      end
    end
  end

  describe '#page_itemtype' do
    subject { helper.page_itemtype(itemtype) }

    context 'when itemtype is passed' do
      let(:itemtype) { 'http://schema.org/Person' }

      it 'stores and returns the itemtype value' do
        attrs = { itemscope: true, itemtype: itemtype }

        expect(subject).to eq attrs
        expect(helper.page_itemtype(nil)).to eq attrs
      end
    end

    context 'when no itemtype is provided' do
      let(:itemtype) { nil }

      it 'returns an empty hash' do
        expect(subject).to eq({})
      end
    end
  end

  describe '#user_status_properties' do
    let(:user) { build(:user) }

    subject { helper.user_status_properties(user) }

    context 'when the user has no status' do
      it 'returns default properties' do
        is_expected.to eq({
          current_emoji: '',
          current_message: '',
          default_emoji: UserStatus::DEFAULT_EMOJI
        })
      end
    end

    context 'when user has a status' do
      let(:time) { 3.hours.ago }

      before do
        user.status = UserStatus.new(message: 'Some message', emoji: 'basketball', availability: 'busy', clear_status_at: time)
      end

      it 'merges the status properties with the defaults' do
        is_expected.to eq({
          current_clear_status_after: time.to_s,
          current_availability: 'busy',
          current_emoji: 'basketball',
          current_message: 'Some message',
          default_emoji: UserStatus::DEFAULT_EMOJI
        })
      end
    end
  end
end
