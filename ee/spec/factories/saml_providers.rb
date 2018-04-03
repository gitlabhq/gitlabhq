FactoryBot.define do
  factory :saml_provider do
    group
    certificate_fingerprint '55:44:33:22:11:aa:bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99'
    sso_url 'https://saml.example.com/adfs/ls'
  end
end
