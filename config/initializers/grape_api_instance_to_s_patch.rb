# frozen_string_literal: true

# Grape 3.2 delegates `Grape::API::Instance.to_s` to `@base`, dropping 2.4's
# `base&.to_s || super` fallback. `@base` is nil for classes inheriting Instance directly,
# as all of GitLab's do, so they stringify to "" while `name` stays correct. Restore the
# fallback for that case only: where `@base` is set Grape needs the delegation, since it
# de-duplicates remounted endpoints by comparing those instances by `to_s`.
module GrapeApiInstanceToSPatch
  def to_s
    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- @base is Grape's own ivar
    return super if @base

    # rubocop:enable Gitlab/ModuleWithInstanceVariables
    # `super` cannot serve this branch: it reaches the delegator and returns "" again.
    Module.instance_method(:to_s).bind_call(self)
  end
end

Grape::API::Instance.singleton_class.prepend(GrapeApiInstanceToSPatch)
