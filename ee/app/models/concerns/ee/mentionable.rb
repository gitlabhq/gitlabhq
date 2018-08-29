# frozen_string_literal: true

module EE
  module Mentionable
    extend ::Gitlab::Utils::Override

    private

    override :extracted_mentionables
    def extracted_mentionables(refs)
      super + refs.epics
    end
  end
end
