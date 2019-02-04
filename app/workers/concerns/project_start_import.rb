# frozen_string_literal: true

# Used in EE by mirroring
module ProjectStartImport
  def start(import_state)
    if import_state.started? && import_state.jid == self.jid
      return true
    end

    import_state.start
  end
end
