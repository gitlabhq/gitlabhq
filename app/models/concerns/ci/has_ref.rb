# frozen_string_literal: true

##
# We will disable `ref` and `sha` attributes in `Ci::Build` in the future
# and remove this module in favor of Ci::Processable.
module Ci
  module HasRef
    extend ActiveSupport::Concern

    def branch?
      !tag? && !merge_request?
    end

    def git_ref
      if branch?
        Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
      elsif tag?
        Gitlab::Git::TAG_REF_PREFIX + ref.to_s
      end
    end

    # A slugified version of the build ref, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Maximum length is 63 bytes
    #   * First/Last Character is not a hyphen
    def ref_slug
      Gitlab::Utils.slugify(ref.to_s)
    end
  end
end
