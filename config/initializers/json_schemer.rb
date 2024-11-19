# frozen_string_literal: true

JSONSchemer.configure do |config|
  categories_filepath = Rails.root.join('config/feature_categories.yml')
  feature_categories = YAML.load_file(categories_filepath)

  config.formats['known_product_category'] = proc do |category, _format|
    feature_categories.include?(category)
  end
end
