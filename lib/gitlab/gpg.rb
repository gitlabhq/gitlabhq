# frozen_string_literal: true

module Gitlab
  module Gpg
    extend self

    CleanupError = Class.new(StandardError)
    BG_CLEANUP_RUNTIME_S = 10
    FG_CLEANUP_RUNTIME_S = 0.5

    MUTEX = Mutex.new

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

    def subkeys_from_key(key)
      using_tmp_keychain do
        fingerprints = CurrentKeyChain.fingerprints_from_key(key)
        raw_keys     = GPGME::Key.find(:public, fingerprints)

        raw_keys.each_with_object({}) do |raw_key, grouped_subkeys|
          primary_subkey_id = raw_key.primary_subkey.keyid

          grouped_subkeys[primary_subkey_id] = raw_key.subkeys[1..-1].map do |s|
            { keyid: s.keyid, fingerprint: s.fingerprint }
          end
        end
      end
    end

    def user_infos_from_key(key)
      using_tmp_keychain do
        fingerprints = CurrentKeyChain.fingerprints_from_key(key)

        GPGME::Key.find(:public, fingerprints).flat_map do |raw_key|
          raw_key.uids.each_with_object([]) do |uid, arr|
            name = uid.name.force_encoding('UTF-8')
            email = uid.email.force_encoding('UTF-8')
            arr << { name: name, email: email.downcase } if name.valid_encoding? && email.valid_encoding?
          end
        end
      end
    end

    # Allows thread safe switching of temporary keychain files
    #
    # 1. The current thread may use nesting of temporary keychain
    # 2. Another thread needs to wait for the lock to be released
    def using_tmp_keychain(&block)
      if MUTEX.locked? && MUTEX.owned?
        optimistic_using_tmp_keychain(&block)
      else
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          MUTEX.synchronize do
            optimistic_using_tmp_keychain(&block)
          end
        end
      end
    end

    # 1. Returns the custom home directory if one has been set by calling
    #    `GPGME::Engine.home_dir=`
    # 2. Returns the default home directory otherwise
    def current_home_dir
      GPGME::Engine.info.first.home_dir || GPGME::Engine.dirinfo('homedir')
    end

    private

    def optimistic_using_tmp_keychain
      previous_dir = current_home_dir
      tmp_dir = Dir.mktmpdir
      GPGME::Engine.home_dir = tmp_dir
      tmp_keychains_created.increment

      yield
    ensure
      GPGME::Engine.home_dir = previous_dir

      begin
        cleanup_tmp_dir(tmp_dir)
      rescue CleanupError => e
        folder_contents = Dir.children(tmp_dir)
        # This means we left a GPG-agent process hanging. Logging the problem in
        # sentry will make this more visible.
        Gitlab::Sentry.track_exception(e,
                                       issue_url: 'https://gitlab.com/gitlab-org/gitlab/issues/20918',
                                       extra: { tmp_dir: tmp_dir, contents: folder_contents })
      end

      tmp_keychains_removed.increment unless File.exist?(tmp_dir)
    end

    def cleanup_tmp_dir(tmp_dir)
      # Retry when removing the tmp directory failed, as we may run into a
      # race condition:
      # The `gpg-agent` agent process may clean up some files as well while
      # `FileUtils.remove_entry` is iterating the directory and removing all
      # its contained files and directories recursively, which could raise an
      # error.
      # Failing to remove the tmp directory could leave the `gpg-agent` process
      # running forever.
      Retriable.retriable(max_elapsed_time: cleanup_time, base_interval: 0.1) do
        FileUtils.remove_entry(tmp_dir) if File.exist?(tmp_dir)
      end
    rescue => e
      raise CleanupError, e
    end

    def cleanup_time
      Sidekiq.server? ? BG_CLEANUP_RUNTIME_S : FG_CLEANUP_RUNTIME_S
    end

    def tmp_keychains_created
      @tmp_keychains_created ||= Gitlab::Metrics.counter(:gpg_tmp_keychains_created_total,
                                                         'The number of temporary GPG keychains created')
    end

    def tmp_keychains_removed
      @tmp_keychains_removed ||= Gitlab::Metrics.counter(:gpg_tmp_keychains_removed_total,
                                                         'The number of temporary GPG keychains removed')
    end
  end
end
