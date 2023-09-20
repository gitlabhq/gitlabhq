# frozen_string_literal: true

module LooseForeignKeys
  # This is a modification tracker with the additional limits that can be enabled
  # for some database via an OPS Feature Flag.

  class TurboModificationTracker < ModificationTracker
    extend ::Gitlab::Utils::Override

    override :max_runtime
    def max_runtime
      45.seconds
    end

    override :max_deletes
    def max_deletes
      200_000
    end

    override :max_updates
    def max_updates
      150_000
    end
  end
end
