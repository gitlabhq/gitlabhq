module Gitlab
  module Gpg
    extend self

    module CurrentKeyChain
      extend self

      def add(key)
        GPGME::Key.import(key)
      end

      def fingerprints_from_key(key)
        import = GPGME::Key.import(key)

        return [] if import.imported == 0

        import.imports.map(&:fingerprint)
      end
    end

    def fingerprints_from_key(key)
      using_tmp_keychain do
        CurrentKeyChain.fingerprints_from_key(key)
      end
    end

    def primary_keyids_from_key(key)
      using_tmp_keychain do
        fingerprints = CurrentKeyChain.fingerprints_from_key(key)

        GPGME::Key.find(:public, fingerprints).map { |raw_key| raw_key.primary_subkey.keyid }
      end
    end

    def user_infos_from_key(key)
      using_tmp_keychain do
        fingerprints = CurrentKeyChain.fingerprints_from_key(key)

        GPGME::Key.find(:public, fingerprints).flat_map do |raw_key|
          raw_key.uids.map { |uid| { name: uid.name, email: uid.email } }
        end
      end
    end

    def using_tmp_keychain
      Dir.mktmpdir do |dir|
        previous_dir = current_home_dir

        GPGME::Engine.home_dir = dir

        return_value = yield

        GPGME::Engine.home_dir = previous_dir

        return_value
      end
    end

    # 1. Returns the custom home directory if one has been set by calling
    #    `GPGME::Engine.home_dir=`
    # 2. Returns the default home directory otherwise
    def current_home_dir
      GPGME::Engine.info.first.home_dir || GPGME::Engine.dirinfo('homedir')
    end
  end
end
