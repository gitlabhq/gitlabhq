# frozen_string_literal: true

module InjectEnterpriseEditionModule
  def prepend_if_ee(constant)
    prepend(constant.constantize) if Gitlab.ee?
  end

  def extend_if_ee(constant)
    extend(constant.constantize) if Gitlab.ee?
  end

  def include_if_ee(constant)
    include(constant.constantize) if Gitlab.ee?
  end
end

Module.prepend(InjectEnterpriseEditionModule)
