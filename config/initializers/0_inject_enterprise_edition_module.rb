# frozen_string_literal: true

require 'active_support/inflector'

module InjectEnterpriseEditionModule
  def prepend_if_ee(constant, with_descendants: false)
    return unless Gitlab.ee?

    prepend_module(constant.constantize, with_descendants)
  end

  def extend_if_ee(constant)
    extend(constant.constantize) if Gitlab.ee?
  end

  def include_if_ee(constant)
    include(constant.constantize) if Gitlab.ee?
  end

  def prepend_ee_mod(with_descendants: false)
    return unless Gitlab.ee?

    prepend_module(ee_module, with_descendants)
  end

  def extend_ee_mod
    extend(ee_module) if Gitlab.ee?
  end

  def include_ee_mod
    include(ee_module) if Gitlab.ee?
  end

  private

  def prepend_module(mod, with_descendants)
    prepend(mod)

    if with_descendants
      descendants.each { |descendant| descendant.prepend(mod) }
    end
  end

  def ee_module
    ::EE.const_get(name, false)
  end
end

Module.prepend(InjectEnterpriseEditionModule)
