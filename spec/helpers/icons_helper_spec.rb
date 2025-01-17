# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IconsHelper do
  let(:icons_path) { ActionController::Base.helpers.image_path("icons.svg") }

  describe 'sprite_icon_path' do
    it 'returns relative path' do
      expect(sprite_icon_path).to eq(icons_path)
    end

    it 'only calls image_path once when called multiple times' do
      expect(ActionController::Base.helpers).to receive(:image_path).once.and_call_original

      2.times { sprite_icon_path }
    end

    context 'when an asset_host is set in the config it will return an absolute local URL' do
      let(:asset_host) { 'http://assets' }

      before do
        allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
      end

      it 'returns an absolute URL on that asset host' do
        expect(sprite_icon_path)
          .to eq ActionController::Base.helpers.image_path("icons.svg", host: Gitlab.config.gitlab.url)
      end
    end
  end

  describe 'sprite_icon' do
    icon_name = 'clock'

    it 'returns svg icon html with DEFAULT_ICON_SIZE' do
      expect(sprite_icon(icon_name).to_s)
        .to eq "<svg class=\"s#{IconsHelper::DEFAULT_ICON_SIZE}\" data-testid=\"#{icon_name}-icon\"><use href=\"#{icons_path}##{icon_name}\"></use></svg>"
    end

    it 'returns svg icon html without size class' do
      expect(sprite_icon(icon_name, size: nil).to_s)
        .to eq "<svg data-testid=\"#{icon_name}-icon\"><use href=\"#{icons_path}##{icon_name}\"></use></svg>"
    end

    it 'returns svg icon html + size classes' do
      expect(sprite_icon(icon_name, size: 72).to_s)
        .to eq "<svg class=\"s72\" data-testid=\"#{icon_name}-icon\"><use href=\"#{icons_path}##{icon_name}\"></use></svg>"
    end

    it 'returns svg icon html + size + variant classes' do
      expect(sprite_icon(icon_name, size: 72, variant: 'subtle').to_s)
        .to eq "<svg class=\"s72 gl-fill-icon-subtle\" data-testid=\"#{icon_name}-icon\"><use href=\"#{icons_path}##{icon_name}\"></use></svg>"
    end

    it 'returns svg icon html + size classes + additional class' do
      expect(sprite_icon(icon_name, size: 72, css_class: 'icon-danger').to_s)
        .to eq "<svg class=\"s72 icon-danger\" data-testid=\"#{icon_name}-icon\"><use href=\"#{icons_path}##{icon_name}\"></use></svg>"
    end

    it 'returns svg icon html with aria label' do
      expect(sprite_icon(icon_name, size: nil, aria_label: 'label').to_s)
        .to eq "<svg data-testid=\"#{icon_name}-icon\" aria-label=\"label\"><use href=\"#{icons_path}##{icon_name}\"></use></svg>"
    end

    it 'returns a file icon' do
      file_icons_path = ActionController::Base.helpers.image_path("file_icons/file_icons.svg")

      expect(sprite_icon('coffee', file_icon: true).to_s)
        .to eq "<svg class=\"s#{IconsHelper::DEFAULT_ICON_SIZE}\" data-testid=\"coffee-icon\"><use href=\"#{file_icons_path}#coffee\"></use></svg>"
    end

    describe 'non existing icon' do
      let(:helper) do
        Class.new do
          include IconsHelper
        end.new
      end

      non_existing = 'non_existing_icon_sprite'

      it 'raises in development mode' do
        stub_rails_env('development')

        expect(helper).to receive(:parse_sprite_definition).with('icons.json').once.and_call_original
        expect(helper).to receive(:parse_sprite_definition).with('file_icons/file_icons.json').once.and_call_original
        expect { helper.sprite_icon(non_existing) }.to raise_error(ArgumentError, /is not a known icon/)
        expect { helper.sprite_icon(non_existing, file_icon: true) }.to raise_error(ArgumentError, /is not a known icon/)
      end

      it 'raises in test mode' do
        stub_rails_env('test')

        expect(helper).to receive(:parse_sprite_definition).with('icons.json').once.and_call_original
        expect(helper).to receive(:parse_sprite_definition).with('file_icons/file_icons.json').once.and_call_original
        expect { helper.sprite_icon(non_existing) }.to raise_error(ArgumentError, /is not a known icon/)
        expect { helper.sprite_icon(non_existing, file_icon: true) }.to raise_error(ArgumentError, /is not a known icon/)
      end

      it 'does not raise in production mode' do
        stub_rails_env('production')

        expect(helper).not_to receive(:parse_sprite_definition)
        expect { sprite_icon(non_existing) }.not_to raise_error
        expect { sprite_icon(non_existing, file_icon: true) }.not_to raise_error
      end
    end
  end

  describe 'audit icon' do
    it 'returns right icon name for standard auth' do
      icon_name = 'standard'
      expect(audit_icon(icon_name).to_s)
          .to eq sprite_icon('key')
    end

    it 'returns right icon name for two-factor auth' do
      icon_name = 'two-factor'
      expect(audit_icon(icon_name).to_s)
          .to eq sprite_icon('key')
    end

    it 'returns right icon name for google_oauth2 auth' do
      icon_name = 'google_oauth2'
      expect(audit_icon(icon_name).to_s)
          .to eq sprite_icon('google')
    end
  end

  describe 'file_type_icon_class' do
    it 'returns folder class' do
      expect(file_type_icon_class('folder', 0, 'folder_name')).to eq 'folder'
    end

    it 'returns share class' do
      expect(file_type_icon_class('file', '120000', 'link')).to eq 'share'
    end

    it 'returns document class with .pdf' do
      expect(file_type_icon_class('file', 0, 'filename.pdf')).to eq 'document'
    end

    it 'returns doc-image class with .jpg' do
      expect(file_type_icon_class('file', 0, 'filename.jpg')).to eq 'doc-image'
    end

    it 'returns doc-image class with .JPG' do
      expect(file_type_icon_class('file', 0, 'filename.JPG')).to eq 'doc-image'
    end

    it 'returns doc-image class with .png' do
      expect(file_type_icon_class('file', 0, 'filename.png')).to eq 'doc-image'
    end

    it 'returns doc-image class with .apng' do
      expect(file_type_icon_class('file', 0, 'filename.apng')).to eq 'doc-image'
    end

    it 'returns doc-image class with .webp' do
      expect(file_type_icon_class('file', 0, 'filename.webp')).to eq 'doc-image'
    end

    it 'returns doc-compressed class with .tar' do
      expect(file_type_icon_class('file', 0, 'filename.tar')).to eq 'doc-compressed'
    end

    it 'returns doc-compressed class with .TAR' do
      expect(file_type_icon_class('file', 0, 'filename.TAR')).to eq 'doc-compressed'
    end

    it 'returns doc-compressed class with .tar.gz' do
      expect(file_type_icon_class('file', 0, 'filename.tar.gz')).to eq 'doc-compressed'
    end

    it 'returns volume-up class with .mp3' do
      expect(file_type_icon_class('file', 0, 'filename.mp3')).to eq 'volume-up'
    end

    it 'returns volume-up class with .MP3' do
      expect(file_type_icon_class('file', 0, 'filename.MP3')).to eq 'volume-up'
    end

    it 'returns volume-up class with .m4a' do
      expect(file_type_icon_class('file', 0, 'filename.m4a')).to eq 'volume-up'
    end

    it 'returns volume-up class with .wav' do
      expect(file_type_icon_class('file', 0, 'filename.wav')).to eq 'volume-up'
    end

    it 'returns live-preview class with .avi' do
      expect(file_type_icon_class('file', 0, 'filename.avi')).to eq 'live-preview'
    end

    it 'returns live-preview class with .AVI' do
      expect(file_type_icon_class('file', 0, 'filename.AVI')).to eq 'live-preview'
    end

    it 'returns live-preview class with .mp4' do
      expect(file_type_icon_class('file', 0, 'filename.mp4')).to eq 'live-preview'
    end

    it 'returns doc-text class with .odt' do
      expect(file_type_icon_class('file', 0, 'filename.odt')).to eq 'doc-text'
    end

    it 'returns doc-text class with .doc' do
      expect(file_type_icon_class('file', 0, 'filename.doc')).to eq 'doc-text'
    end

    it 'returns doc-text class with .DOC' do
      expect(file_type_icon_class('file', 0, 'filename.DOC')).to eq 'doc-text'
    end

    it 'returns doc-text class with .docx' do
      expect(file_type_icon_class('file', 0, 'filename.docx')).to eq 'doc-text'
    end

    it 'returns document class with .xls' do
      expect(file_type_icon_class('file', 0, 'filename.xls')).to eq 'document'
    end

    it 'returns document class with .XLS' do
      expect(file_type_icon_class('file', 0, 'filename.XLS')).to eq 'document'
    end

    it 'returns document class with .xlsx' do
      expect(file_type_icon_class('file', 0, 'filename.xlsx')).to eq 'document'
    end

    it 'returns doc-chart class with .odp' do
      expect(file_type_icon_class('file', 0, 'filename.odp')).to eq 'doc-chart'
    end

    it 'returns doc-chart class with .ppt' do
      expect(file_type_icon_class('file', 0, 'filename.ppt')).to eq 'doc-chart'
    end

    it 'returns doc-chart class with .PPT' do
      expect(file_type_icon_class('file', 0, 'filename.PPT')).to eq 'doc-chart'
    end

    it 'returns doc-chart class with .pptx' do
      expect(file_type_icon_class('file', 0, 'filename.pptx')).to eq 'doc-chart'
    end

    it 'returns doc-text class with .unknow' do
      expect(file_type_icon_class('file', 0, 'filename.unknow')).to eq 'doc-text'
    end

    it 'returns doc-text class with no extension' do
      expect(file_type_icon_class('file', 0, 'CHANGELOG')).to eq 'doc-text'
    end
  end

  describe '#external_snippet_icon' do
    it 'returns external snippet icon' do
      expect(external_snippet_icon('download').to_s)
        .to eq("<span class=\"gl-snippet-icon gl-snippet-icon-download\"></span>")
    end
  end

  describe 'gl_loading_icon' do
    it 'returns the default spinner markup' do
      expect(gl_loading_icon.to_s)
        .to eq '<div class="gl-spinner-container" role="status"><span aria-hidden class="gl-spinner gl-spinner-sm gl-spinner-dark !gl-align-text-bottom"></span><span class="gl-sr-only !gl-absolute">Loading</span>
</div>'
    end

    context 'when css_class is provided' do
      it 'appends css_class to container element' do
        expect(gl_loading_icon(css_class: 'gl-mr-2').to_s).to match 'gl-spinner-container gl-mr-2'
      end
    end

    context 'when size is provided' do
      it 'sets the size class' do
        expect(gl_loading_icon(size: 'xl').to_s).to match 'gl-spinner-xl'
      end
    end

    context 'when color is provided' do
      it 'sets the color class' do
        expect(gl_loading_icon(color: 'light').to_s).to match 'gl-spinner-light'
      end
    end

    context 'when inline is true' do
      it 'creates an inline container' do
        expect(gl_loading_icon(inline: true).to_s).to start_with '<span class="gl-spinner-container"'
      end
    end
  end
end
