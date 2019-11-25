# frozen_string_literal: true

module GitHelper
  def strip_signature(text)
    text.gsub(/-----BEGIN PGP SIGNATURE-----(.*)-----END PGP SIGNATURE-----/m, "")
    text.gsub(/-----BEGIN PGP MESSAGE-----(.*)-----END PGP MESSAGE-----/m, "")
    text.gsub(/-----BEGIN SIGNED MESSAGE-----(.*)-----END SIGNED MESSAGE-----/m, "")
  end

  def short_sha(text)
    Commit.truncate_sha(text)
  end
end
