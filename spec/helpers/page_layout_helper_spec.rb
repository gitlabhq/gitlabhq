require 'rails_helper'

describe PageLayoutHelper do
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
  end

  describe 'favicon' do
    it 'defaults to favicon.ico' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      expect(helper.favicon).to eq 'favicon.ico'
    end

    it 'has blue favicon for development' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      expect(helper.favicon).to eq 'favicon-green.ico'
    end

    it 'has yellow favicon for canary' do
      stub_env('CANARY', 'true')
      expect(helper.favicon).to eq 'favicon-yellow.ico'
    end

    it 'has yellow favicon for canary' do
      stub_env('CANARY', 'true')
      expect(helper.favicon).to eq 'favicon-yellow.ico'
    end
  end

  describe 'page_image' do
    it 'defaults to the GitLab logo' do
      expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
    end

    %w(project user group).each do |type|
      context "with @#{type} assigned" do
        it "uses #{type.titlecase} avatar if available" do
          object = double(avatar_url: 'http://example.com/uploads/-/system/avatar.png')
          assign(type, object)

          expect(helper.page_image).to eq object.avatar_url
        end

        it 'falls back to the default when avatar_url is nil' do
          object = double(avatar_url: nil)
          assign(type, object)

          expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
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
end
