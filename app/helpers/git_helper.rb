# frozen_string_literal: true

module GitHelper
  def strip_gpg_signature(text)
    text.gsub(/-----BEGIN PGP SIGNATURE-----(.*)-----END PGP SIGNATURE-----/m, "")
  end

  def short_sha(text)
    Commit.truncate_sha(text)
  end
end
