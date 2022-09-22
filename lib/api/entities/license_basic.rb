# frozen_string_literal: true

module API
  module Entities
    # Serializes a Gitlab::Git::DeclaredLicense
    class LicenseBasic < Grape::Entity
      expose :key, :name, :nickname
      expose :url, as: :html_url

      # This was dropped:
      # https://github.com/github/choosealicense.com/commit/325806b42aa3d5b78e84120327ec877bc936dbdd#diff-66df8f1997786f7052d29010f2cbb4c66391d60d24ca624c356acc0ab986f139
      expose :source_url do |_|
        nil
      end
    end
  end
end
