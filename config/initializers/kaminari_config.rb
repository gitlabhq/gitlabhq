# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 20
  config.max_per_page = 100
  # config.window = 4
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
end
