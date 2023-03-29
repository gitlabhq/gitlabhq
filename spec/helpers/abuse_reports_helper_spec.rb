# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportsHelper, feature_category: :insider_threat do
  describe '#valid_image_mimetypes' do
    subject(:valid_image_mimetypes) { helper.valid_image_mimetypes }

    it {
      is_expected.to eq('image/png, image/jpg, image/jpeg, image/gif, image/bmp, image/tiff, image/ico or image/webp')
    }
  end
end
