# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Every controller", feature_category: :scalability do
  context "feature categories" do
    let_it_be(:feature_categories) do
      Gitlab::FeatureCategories.default.categories.map(&:to_sym).to_set
    end

    let_it_be(:controller_actions) do
      Gitlab::RequestEndpoints.all_controller_actions
    end

    let_it_be(:routes_without_category) do
      controller_actions.map do |controller, action|
        next if controller.feature_category_for_action(action)

        "#{controller}##{action}"
      end.compact
    end

    it "has feature categories" do
      expect(routes_without_category).to be_empty, "#{routes_without_category} did not have a category"
    end

    it "completed controllers don't get new routes without categories" do
      completed_controllers = [Projects::MergeRequestsController].map(&:to_s)

      newly_introduced_missing_category = routes_without_category.select do |route|
        completed_controllers.any? { |controller| route.start_with?(controller) }
      end

      expect(newly_introduced_missing_category).to be_empty
    end

    it "recognizes the feature categories" do
      routes_unknown_category = controller_actions.map do |controller, action|
        used_category = controller.feature_category_for_action(action)
        next unless used_category
        next if used_category == :not_owned

        ["#{controller}##{action}", used_category] unless feature_categories.include?(used_category)
      end.compact

      expect(routes_unknown_category).to be_empty, "#{routes_unknown_category.first(10)} had an unknown category"
    end

    it "doesn't define or exclude categories on removed actions", :aggregate_failures do
      controller_actions.group_by(&:first).each do |controller, controller_action|
        existing_actions = controller_action.map(&:last)
        used_actions = actions_defined_in_feature_category_config(controller)
        non_existing_used_actions = used_actions - existing_actions

        expect(non_existing_used_actions).to be_empty,
          "#{controller} used #{non_existing_used_actions} to define feature category, but the route does not exist"
      end
    end
  end

  def constantize_controller(name)
    "#{name.camelize}Controller".constantize
  rescue NameError
    nil # some controllers, like the omniauth ones are dynamic
  end

  def actions_defined_in_feature_category_config(controller)
    controller.send(:class_attributes)[:endpoint_attributes_config].defined_actions
  end
end
