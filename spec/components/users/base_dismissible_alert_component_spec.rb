# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BaseDismissibleAlertComponent, feature_category: :shared do
  let(:user) { build_stubbed(:user) }
  let(:dismiss_options) { { user: user, feature_id: :test_feature } }

  where(:method_name) do
    %i[
      dismiss_endpoint
      callout_class
      user_dismissed_alert?
    ]
  end

  with_them do
    it 'raises NoMethodError when abstract method is not implemented' do
      error_message = /This method must be implemented in a subclass/

      expect do
        render_inline(component_without(method_name))
      end.to raise_error(NoMethodError, error_message)
    end
  end

  private

  def component_without(method = nil)
    klass = stub_const('TestDismissibleAlertComponent', Class.new(described_class))

    complete_methods = [:dismiss_endpoint, :callout_class, :user_dismissed_alert?]

    complete_methods.each do |m|
      next if m == method

      klass.class_eval do
        define_method(m) do
          case m
          when :dismiss_endpoint then '/test/callouts'
          when :callout_class then Users::Callout
          when :user_dismissed_alert? then false
          end
        end
      end
    end

    allow(Users::Callout).to receive(:feature_names).and_return([:test_feature])

    klass.new(title: 'Test Alert', dismiss_options: dismiss_options)
  end
end
