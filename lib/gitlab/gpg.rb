module Gitlab
  module Gpg
    extend self

    def fingerprints_from_key(key)
      using_tmp_keychain do
        import = GPGME::Key.import(key)

        return [] if import.imported == 0

        import.imports.map(&:fingerprint)
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
