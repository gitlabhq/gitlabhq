module Gitlab
  module GitRefValidator
    extend self
    # Validates a given name against the git reference specification
    #
    # Returns true for a valid reference name, false otherwise
    def validate(ref_name)
      Gitlab::Utils.system_silent(
        %W(#{Gitlab.config.git.bin_path} check-ref-format refs/#{ref_name}))
    end
  end
end
