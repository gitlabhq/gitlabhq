# frozen_string_literal: true

require "fast_spec_helper"
require "rspec-parameterized"
require_relative "../../../../app/controllers/concerns/controller_with_feature_category/config"

RSpec.describe ControllerWithFeatureCategory::Config do
  describe "#matches?" do
    using RSpec::Parameterized::TableSyntax

    where(:only_actions, :except_actions, :if_proc, :unless_proc, :test_action, :expected) do
      nil         | nil         | nil   | nil   | "action"   | true
      [:included] | nil         | nil   | nil   | "action"   | false
      [:included] | nil         | nil   | nil   | "included" | true
      nil         | [:excluded] | nil   | nil   | "excluded" | false
      nil         | nil         | true  | nil   | "action"   | true
      [:included] | nil         | true  | nil   | "action"   | false
      [:included] | nil         | true  | nil   | "included" | true
      nil         | [:excluded] | true  | nil   | "excluded" | false
      nil         | nil         | false | nil   | "action"   | false
      [:included] | nil         | false | nil   | "action"   | false
      [:included] | nil         | false | nil   | "included" | false
      nil         | [:excluded] | false | nil   | "excluded" | false
      nil         | nil         | nil   | true  | "action"   | false
      [:included] | nil         | nil   | true  | "action"   | false
      [:included] | nil         | nil   | true  | "included" | false
      nil         | [:excluded] | nil   | true  | "excluded" | false
      nil         | nil         | nil   | false | "action"   | true
      [:included] | nil         | nil   | false | "action"   | false
      [:included] | nil         | nil   | false | "included" | true
      nil         | [:excluded] | nil   | false | "excluded" | false
      nil         | nil         | true  | false | "action"   | true
      [:included] | nil         | true  | false | "action"   | false
      [:included] | nil         | true  | false | "included" | true
      nil         | [:excluded] | true  | false | "excluded" | false
      nil         | nil         | false | true  | "action"   | false
      [:included] | nil         | false | true  | "action"   | false
      [:included] | nil         | false | true  | "included" | false
      nil         | [:excluded] | false | true  | "excluded" | false
    end

    with_them do
      let(:config) do
        if_to_proc = if_proc.nil? ? nil : -> (_) { if_proc }
        unless_to_proc = unless_proc.nil? ? nil : -> (_) { unless_proc }

        described_class.new(:category, only_actions, except_actions, if_to_proc, unless_to_proc)
      end

      specify { expect(config.matches?(test_action)).to be(expected) }
    end
  end
end
