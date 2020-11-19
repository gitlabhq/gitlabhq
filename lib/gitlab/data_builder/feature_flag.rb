# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module FeatureFlag
      extend self

      def build(feature_flag, user)
        {
          object_kind: 'feature_flag',
          project: feature_flag.project.hook_attrs,
          user: user.hook_attrs,
          user_url: Gitlab::UrlBuilder.build(user),
          object_attributes: feature_flag.hook_attrs
        }
      end
    end
  end
end
