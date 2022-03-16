# frozen_string_literal: true

# Renders a GlToggle root element
# To actually initialize the component, make sure to call the initToggle helper from ~/toggles.
class Pajamas::ToggleComponent < Pajamas::Component
  LABEL_POSITION_OPTIONS = [:top, :left, :hidden].freeze

  # @param [String] classes
  # @param [String] label
  # @param [Symbol] label_position :top, :left or :hidden
  # @param [String] id
  # @param [String] name
  # @param [String] help
  # @param [Hash] data
  # @param [Boolean] is_disabled
  # @param [Boolean] is_checked
  # @param [Boolean] is_loading
  def initialize(
    classes:, label: nil, label_position: nil,
    id: nil, name: nil, help: nil, data: {},
    is_disabled: false, is_checked: false, is_loading: false)

    @id = id
    @name = name
    @classes = classes
    @label = label
    @label_position = filter_attribute(label_position, LABEL_POSITION_OPTIONS)
    @help = help
    @data = data
    @is_disabled = is_disabled
    @is_checked = is_checked
    @is_loading = is_loading
  end
end
