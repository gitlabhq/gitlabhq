# frozen_string_literal: true

module TrackingHelper
  def tracking_attrs(label, action, property)
    return {} unless ::Gitlab::Tracking.enabled?

    {
      data: {
        track_label: label,
        track_action: action,
        track_property: property
      }
    }
  end

  def tracking_attrs_data(label, action, property)
    tracking_attrs(label, action, property).fetch(:data, {})
  end
end
