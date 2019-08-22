# Set default values for email_smime settings
class SmimeSignatureSettings
  def self.parse(email_smime)
    email_smime ||= Settingslogic.new({})
    email_smime['enabled'] = false unless email_smime['enabled']
    email_smime['key_file'] ||= Rails.root.join('.gitlab_smime_key')
    email_smime['cert_file'] ||= Rails.root.join('.gitlab_smime_cert')

    email_smime
  end
end
