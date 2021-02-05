# frozen_string_literal: true

module EnableSearchSettingsHelper
  def enable_search_settings(locals: {})
    content_for :before_content do
      render "shared/search_settings", locals
    end
  end
end
