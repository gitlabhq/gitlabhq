# frozen_string_literal: true

module ReadmeHelper
  # @return [Hash]
  def vue_readme_header_additional_data
    {}
  end
end

ReadmeHelper.prepend_mod_with("ReadmeHelper")
