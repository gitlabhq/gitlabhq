# frozen_string_literal: true

module Mcp
  module Tools
    module Toolsets
      ALWAYS_ON  = %i[meta].freeze
      DEFAULT    = %i[core merge_requests work_items repository ci].freeze
      OPT_IN     = %i[duo_agent_platform wikis code_security].freeze
      ALL        = (ALWAYS_ON + DEFAULT + OPT_IN).freeze
      UNASSIGNED = :unassigned
    end
  end
end
