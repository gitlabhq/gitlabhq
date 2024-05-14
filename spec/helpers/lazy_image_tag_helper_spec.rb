# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LazyImageTagHelper do
  describe '#image_tag' do
    let(:image_src) { '/path/to/image.jpg' }
    let(:dark_image_src) { '/path/to/image_dark.jpg' }

    context 'when only source passed' do
      let(:current_user) { create(:user) }
      let(:result) { image_tag(image_src) }

      it 'returns a lazy image tag by default' do
        expect(result).to eq(
          "<img data-src=\"#{image_src}\" class=\"lazy\" src=\"#{placeholder_image}\" />"
        )
      end
    end

    context 'when lazy mode is disabled' do
      let(:current_user) { create(:user) }
      let(:result) { image_tag(image_src, lazy: false) }

      it 'returns a normal image tag' do
        expect(result).to eq(
          "<img src=\"#{image_src}\" />"
        )
      end
    end

    context 'when Dark Mode is enabled' do
      let(:current_user) { create(:user, color_mode_id: 2) }

      context 'when auto dark enabled' do
        let(:result) { image_tag(image_src, auto_dark: true) }

        it 'adds an auto dark mode class from gitlab-ui' do
          expect(result).to eq(
            "<img class=\"gl-dark-invert-keep-hue lazy\" data-src=\"#{image_src}\" src=\"#{placeholder_image}\" />"
          )
        end
      end

      context 'when auto dark disabled' do
        let(:result) { image_tag(image_src, auto_dark: false) }

        it 'does nothing' do
          expect(result).to eq(
            "<img data-src=\"#{image_src}\" class=\"lazy\" src=\"#{placeholder_image}\" />"
          )
        end
      end

      context 'when dark variant is present' do
        let(:result) { image_tag(image_src, dark_variant: dark_image_src) }

        it 'uses dark variant as a source' do
          expect(result).to eq(
            "<img data-src=\"#{dark_image_src}\" class=\"lazy\" src=\"#{placeholder_image}\" />"
          )
        end
      end
    end

    context 'when Dark Mode is disabled' do
      let(:current_user) { create(:user, color_mode_id: 1) }

      context 'when auto dark enabled' do
        let(:result) { image_tag(image_src, auto_dark: true) }

        it 'does not add a dark mode class from gitlab-ui' do
          expect(result).to eq(
            "<img data-src=\"#{image_src}\" class=\"lazy\" src=\"#{placeholder_image}\" />"
          )
        end
      end

      context 'when auto dark disabled' do
        let(:result) { image_tag(image_src, auto_dark: true) }

        it 'does nothing' do
          expect(result).to eq(
            "<img data-src=\"#{image_src}\" class=\"lazy\" src=\"#{placeholder_image}\" />"
          )
        end
      end

      context 'when dark variant is present' do
        let(:result) { image_tag(image_src, dark_variant: dark_image_src) }

        it 'uses original image as a source' do
          expect(result).to eq(
            "<img data-src=\"#{image_src}\" class=\"lazy\" src=\"#{placeholder_image}\" />"
          )
        end
      end
    end

    context 'when auto_dark and dark_variant are both passed' do
      let(:current_user) { create(:user) }

      it 'does not add a dark mode class from gitlab-ui' do
        expect { image_tag('image.jpg', dark_variant: 'image_dark.jpg', auto_dark: true) }
          .to raise_error(ArgumentError, 'dark_variant and auto_dark are mutually exclusive')
      end
    end
  end
end
