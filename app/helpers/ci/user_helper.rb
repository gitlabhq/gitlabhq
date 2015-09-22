module Ci
  module UserHelper
    def user_avatar_url(user = nil, size = nil, default = 'identicon')
      size = 40 if size.nil? || size <= 0

      if user.blank? || user.avatar_url.blank?
        'ci/no_avatar.png'
      elsif /^(http(s?):\/\/(www|secure)\.gravatar\.com\/avatar\/(\w*))/ =~ user.avatar_url
        Regexp.last_match[0] + "?s=#{size}&d=#{default}"
      else
        user.avatar_url
      end
    end
  end
end
