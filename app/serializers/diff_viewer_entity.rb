# frozen_string_literal: true

class DiffViewerEntity < Grape::Entity
  # Partial name refers directly to a Rails feature, let's avoid
  # using this on the frontend.
  expose :partial_name, as: :name
  expose :error do |diff_viewer|
    diff_viewer.render_error_message
  end
end
