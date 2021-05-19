# frozen_string_literal: true

module InProductMarketingHelper
  def inline_image_link(image, options)
    attachments.inline[image] = File.read(Rails.root.join("app/assets/images", image))
    image_tag attachments[image].url, **options
  end

  def about_link(image, width)
    link_to inline_image_link(image, { width: width, style: "width: #{width}px;", alt: s_('InProductMarketing|go to about.gitlab.com') }), 'https://about.gitlab.com/'
  end
end
