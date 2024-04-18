# frozen_string_literal: true

module InProductMarketingHelper
  def inline_image_link(image, options)
    asset_path = Rails.root.join("app/assets/images").to_s
    image_path = File.join(asset_path, image)
    Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!(image_path, [asset_path])
    attachments.inline[image] = File.read(image_path)
    image_tag attachments[image].url, **options
  end

  def about_link(image, width)
    link_to inline_image_link(image, { width: width, style: "width: #{width}px;", alt: s_('InProductMarketing|go to about.gitlab.com') }), 'https://about.gitlab.com/'
  end
end
