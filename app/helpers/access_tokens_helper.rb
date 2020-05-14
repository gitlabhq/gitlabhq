# frozen_string_literal: true

module AccessTokensHelper
  def scope_description(prefix)
    prefix == :project_access_token ? [:doorkeeper, :project_access_token_scope_desc] : [:doorkeeper, :scope_desc]
  end
end
