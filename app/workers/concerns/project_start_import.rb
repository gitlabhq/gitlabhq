# Used in EE by mirroring
module ProjectStartImport
  def start(project)
    if project.import_started? && project.import_jid == self.jid
      return true
    end

    project.import_start
  end
end
