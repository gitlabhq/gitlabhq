# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::PlayableLinkFilter do
  # The filter is abstract: `Banzai::Filter::AudioLinkFilter` and
  # `Banzai::Filter::VideoLinkFilter` supply the media type and extensions.
  let(:filter_class) do
    Class.new(described_class) do
      def media_type
        'video'
      end

      def safe_media_ext
        %w[mp4]
      end

      def extra_element_attrs(_element)
        { width: '400' }
      end
    end
  end

  def filter(html)
    filter_class.call(html, {})
  end

  it 'wraps a playable image in a media container' do
    doc = filter('<img src="/x/movie.mp4" title="a title">')

    container = doc.at_css('span')
    expect(container['class']).to eq('media-container video-container')

    video = container.at_css('video')
    expect(video['src']).to eq('/x/movie.mp4')
    expect(video['data-title']).to eq('a title')
    expect(video['width']).to eq('400')
  end

  it 'falls back to the alt text for the title' do
    doc = filter('<img src="/x/movie.mp4" alt="alt text">')

    expect(doc.at_css('video')['data-title']).to eq('alt text')
  end

  it 'carries the canonical src over' do
    doc = filter('<img src="/proxied/movie.mp4" data-canonical-src="/original/movie.mp4">')

    expect(doc.at_css('video')['data-canonical-src']).to eq('/original/movie.mp4')
  end

  it 'leaves an image with an unlisted extension alone' do
    doc = filter('<img src="/x/picture.png">')

    expect(doc.at_css('video')).to be_nil
    expect(doc.at_css('img')).not_to be_nil
  end

  it 'leaves an image that is already a link alone' do
    doc = filter('<a href="/x"><img src="/x/movie.mp4"></a>')

    expect(doc.at_css('video')).to be_nil
  end

  it 'raises on the abstract hooks' do
    instance = described_class.new('')

    expect { instance.send(:media_type) }.to raise_error(NotImplementedError)
    expect { instance.send(:safe_media_ext) }.to raise_error(NotImplementedError)
  end
end
