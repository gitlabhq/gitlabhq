# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InProductMarketingHelper, feature_category: :activation do
  describe '#inline_image_link' do
    let(:image) { 'gitlab_logo.png' }

    before do
      attachments = instance_double(Mail::AttachmentsList).as_null_object

      allow(helper).to receive(:attachments).and_return(attachments)
      allow(attachments).to receive(:[]).with(image).and_return(Mail::Part.new)
    end

    it 'checks for path traversal' do
      asset_path = Rails.root.join("app/assets/images").to_s
      image_path = File.join(asset_path, image)

      expect(Gitlab::PathTraversal).to receive(:check_allowed_absolute_path_and_path_traversal!)
        .with(image_path, [asset_path])

      helper.inline_image_link(image, {})
    end
  end
end
