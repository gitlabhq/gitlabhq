module BadgesHelper
  def verified_email_badge(email, verified)
    css_classes = %w(btn btn-xs disabled)

    css_classes << 'btn-success' if verified

    content_tag 'span', class: css_classes do
      "#{email} #{verified ? 'Verified' : 'Unverified'}"
    end
  end
end
