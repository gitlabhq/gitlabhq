module GitHelper
  def strip_gpg_signature(text)
    text.gsub(/-----BEGIN PGP SIGNATURE-----(.*)-----END PGP SIGNATURE-----/m, "")
  end

  def short_sha(text)
    text[0...8]
  end
end
