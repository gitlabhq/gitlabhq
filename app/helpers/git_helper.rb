module GitHelper
  def strip_gpg_signature(text)
    text.gsub(/-----BEGIN PGP SIGNATURE-----(.*)-----END PGP SIGNATURE-----/m, "")
  end
end
