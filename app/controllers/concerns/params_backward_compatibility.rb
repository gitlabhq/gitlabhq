# frozen_string_literal: true

module ParamsBackwardCompatibility
  private

  def set_non_archived_param
    archived = params.permit(:archived)[:archived]

    # rubocop:disable Rails/StrongParams -- in-place mutation; strong params syntax would write to a copy
    params[:non_archived] = archived.blank?
    # rubocop:enable Rails/StrongParams
  end
end
