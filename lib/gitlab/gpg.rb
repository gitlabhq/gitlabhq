module Gitlab
  module Gpg
    extend self

    module CurrentKeyChain
      extend self

      def emails(fingerprint)
        GPGME::Key.find(:public, fingerprint).flat_map { |raw_key| raw_key.uids.map(&:email) }
      end
    end

    def fingerprints_from_key(key)
      using_tmp_keychain do
        import = GPGME::Key.import(key)

        return [] if import.imported == 0

        import.imports.map(&:fingerprint)
      end
    end

    def emails_from_key(key)
      using_tmp_keychain do
        import = GPGME::Key.import(key)

        return [] if import.imported == 0

        fingerprints = import.imports.map(&:fingerprint)

        GPGME::Key.find(:public, fingerprints).flat_map { |raw_key| raw_key.uids.map(&:email) }
      end
    end

    def add_to_keychain(key)
      GPGME::Key.import(key)
    end

    def remove_from_keychain(fingerprint)
      GPGME::Key.get(fingerprint).delete!
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
