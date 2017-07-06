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

    def emails_from_key(key)
      using_tmp_keychain do
        fingerprints = CurrentKeyChain.fingerprints_from_key(key)

        GPGME::Key.find(:public, fingerprints).flat_map { |raw_key| raw_key.uids.map(&:email) }
      end
    end

    def using_tmp_keychain
      Dir.mktmpdir do |dir|
        @original_dirs ||= [GPGME::Engine.dirinfo('homedir')]
        @original_dirs.push(dir)

        GPGME::Engine.home_dir = dir

        return_value = yield

        @original_dirs.pop

        GPGME::Engine.home_dir = @original_dirs[-1]

        return_value
      end
    end
  end
end
