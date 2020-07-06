# frozen_string_literal: true

require 'fast_spec_helper'
require_relative "../../../app/controllers/concerns/controller_with_feature_category"
require_relative "../../../app/controllers/concerns/controller_with_feature_category/config"

RSpec.describe ControllerWithFeatureCategory do
  describe ".feature_category_for_action" do
    let(:base_controller) do
      Class.new do
        include ControllerWithFeatureCategory
      end
    end

    let(:controller) do
      Class.new(base_controller) do
        feature_category :baz
        feature_category :foo, except: %w(update edit)
        feature_category :bar, only: %w(index show)
        feature_category :quux, only: %w(destroy)
        feature_category :quuz, only: %w(destroy)
      end
    end

    let(:subclass) do
      Class.new(controller) do
        feature_category :qux, only: %w(index)
      end
    end

    it "is nil when nothing was defined" do
      expect(base_controller.feature_category_for_action("hello")).to be_nil
    end

    it "returns the expected category", :aggregate_failures do
      expect(controller.feature_category_for_action("update")).to eq(:baz)
      expect(controller.feature_category_for_action("hello")).to eq(:foo)
      expect(controller.feature_category_for_action("index")).to eq(:bar)
    end

    it "returns the closest match for categories defined in subclasses" do
      expect(subclass.feature_category_for_action("index")).to eq(:qux)
      expect(subclass.feature_category_for_action("show")).to eq(:bar)
    end

    it "returns the last defined feature category when multiple match" do
      expect(controller.feature_category_for_action("destroy")).to eq(:quuz)
    end

    it "raises an error when using including and excluding the same action" do
      expect do
        Class.new(base_controller) do
          feature_category :hello, only: [:world], except: [:world]
        end
      end.to raise_error(%r(cannot configure both `only` and `except`))
    end

    it "raises an error when using unknown arguments" do
      expect do
        Class.new(base_controller) do
          feature_category :hello, hello: :world
        end
      end.to raise_error(%r(unknown arguments))
    end
  end
end
