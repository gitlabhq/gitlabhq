# frozen_string_literal: true

class WebIdeTerminalSerializer < BaseSerializer
  entity WebIdeTerminalEntity

  def represent(resource, opts = {})
    resource = WebIdeTerminal.new(resource) if resource.is_a?(Ci::Build)

    super
  end
end
