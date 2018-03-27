# Gitaly note: JV: does not need to be migrated, works without a repo.

module Gitlab
  module GitRefValidator
    extend self
    # Validates a given name against the git reference specification
    #
    # Returns true for a valid reference name, false otherwise
    def validate(ref_name)
      return false if ref_name.start_with?('refs/heads/')
      return false if ref_name.start_with?('refs/remotes/')

      Gitlab::Utils.system_silent(
        %W(#{Gitlab.config.git.bin_path} check-ref-format --branch #{ref_name}))
    end
  end
end
