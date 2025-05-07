# frozen_string_literal: true

module Groups
  class ImportHistoriesController < Groups::ApplicationController
    feature_category :importers
    urgency :low

    before_action :authorize_admin_group!

    before_action do
      render_404 unless Feature.enabled?(:group_import_history_visibility, @group)
    end
  end
end
