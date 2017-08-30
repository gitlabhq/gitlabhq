class UpdateGpgSignaturesVerificationStatus < ActiveRecord::Migration
  DOWNTIME = false

  def up
    GpgSignature.where(verification_status: nil).find_each do |gpg_signature|
      gpg_signature.gpg_commit.update_signature!(gpg_signature)
    end
  end

  def down
    # we can't revert setting the verification_status, but actually we don't
    # need to really, as setting this is not a harmful change.
  end
end
