# frozen_string_literal: true

require 'active_support/inflector'

module InjectComModule
  def prepend_if_com(constant, with_descendants: false)
    return unless Gitlab.com?

    com_module = constant.constantize
    prepend(com_module)

    if with_descendants
      descendants.each { |descendant| descendant.prepend(com_module) }
    end
  end

  def extend_if_com(constant)
    extend(constant.constantize) if Gitlab.com?
  end

  def include_if_com(constant)
    include(constant.constantize) if Gitlab.com?
  end
end

Module.prepend(InjectComModule)
