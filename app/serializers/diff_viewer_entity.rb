# frozen_string_literal: true

class DiffViewerEntity < Grape::Entity
  expose :partial_name, as: :name
  expose :render_error, as: :error
  expose :render_error_message, as: :error_message
  expose :collapsed?, as: :collapsed
  expose :whitespace_only, if: ->(_, _) { Feature.enabled?(:add_ignore_all_white_spaces) } do |_, options|
    options[:whitespace_only]
  end
end
