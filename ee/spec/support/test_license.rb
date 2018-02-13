class TestLicense
  def self.init
    Gitlab::License.encryption_key = OpenSSL::PKey::RSA.generate(2048)

    FactoryBot.create(:license)
  end
end
