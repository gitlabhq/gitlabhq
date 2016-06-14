class CanonicalizeKerberosIdentities < ActiveRecord::Migration
  # This migration can be performed online without errors.
  # It makes sure that all Kerberos identities are in canonical form
  # with a realm name (`username` => `username@DEFAULT.REALM`).
  # Before this migration, Kerberos identities using the default realm are typically stored
  # without the realm part.

  def kerberos_default_realm
    @kerberos_default_realm ||= begin
      require "krb5_auth"
      krb5 = ::Krb5Auth::Krb5.new
      default_realm = krb5.get_default_realm
      krb5.close # release memory allocated by the krb5 library
      default_realm || ''
    rescue StandardError
      '' # could not find the system's default realm, maybe there's no Kerberos at all
    end
  end

  def change
    reversible do |dir|
      return unless kerberos_default_realm.present?

      dir.up do
        # add the default realm to any kerberos identity not having a realm already
        execute("UPDATE identities SET extern_uid = CONCAT(extern_uid, '@#{quote_string(kerberos_default_realm)}')
                 WHERE provider = 'kerberos' AND extern_uid NOT LIKE '%@%'")
      end

      dir.down do
        # remove the realm from kerberos identities using the default realm
        execute("UPDATE identities SET extern_uid = REPLACE(extern_uid, '@#{quote_string(kerberos_default_realm)}', '')
                 WHERE provider = 'kerberos' AND extern_uid LIKE '%@#{quote_string(kerberos_default_realm)}'")
      end
    end
  end
end
