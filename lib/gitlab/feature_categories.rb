# frozen_string_literal: true

module Gitlab
  class FeatureCategories
    FEATURE_CATEGORY_DEFAULT = 'unknown'

    attr_reader :categories

    def self.default
      @default ||= self.load_from_yaml
    end

    def self.load_from_yaml
      categories = YAML.load_file(Rails.root.join('config', 'feature_categories.yml'))

      new(categories)
    end

    def initialize(categories)
      @categories = categories.to_set
    end

    # If valid, returns a feature category from the given request.
    def from_request(request)
      category = request.headers["HTTP_X_GITLAB_FEATURE_CATEGORY"].presence

      return unless category && valid?(category)

      return unless ::Gitlab::RequestForgeryProtection.verified?(request.env)

      category
    end

    def get!(feature_category)
      return feature_category if valid?(feature_category)

      raise "Unknown feature category: #{feature_category}" if Gitlab.dev_or_test_env?

      FEATURE_CATEGORY_DEFAULT
    end

    def valid?(category)
      categories.include?(category.to_s)
    end
  end
end
