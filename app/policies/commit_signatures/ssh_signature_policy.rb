# frozen_string_literal: true

module CommitSignatures
  class SshSignaturePolicy < BasePolicy
    delegate { @subject.project }
  end
end
