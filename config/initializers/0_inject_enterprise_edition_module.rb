# frozen_string_literal: true

require 'active_support/inflector'

module InjectEnterpriseEditionModule
  def prepend_mod_with(constant_name, namespace: Object, with_descendants: false)
    each_extension_for(constant_name, namespace) do |constant|
      prepend_module(constant, with_descendants)
    end
  end

  def extend_mod_with(constant_name, namespace: Object)
    each_extension_for(
      constant_name,
      namespace,
      &method(:extend))
  end

  def include_mod_with(constant_name, namespace: Object)
    each_extension_for(
      constant_name,
      namespace,
      &method(:include))
  end

  def prepend_mod(with_descendants: false)
    prepend_mod_with(name, with_descendants: with_descendants) # rubocop: disable Cop/InjectEnterpriseEditionModule
  end

  def extend_mod
    extend_mod_with(name) # rubocop: disable Cop/InjectEnterpriseEditionModule
  end

  def include_mod
    include_mod_with(name) # rubocop: disable Cop/InjectEnterpriseEditionModule
  end

  private

  def prepend_module(mod, with_descendants)
    prepend(mod)

    if with_descendants
      descendants.each { |descendant| descendant.prepend(mod) }
    end
  end

  def each_extension_for(constant_name, namespace)
    Gitlab.extensions.each do |extension_name|
      extension_namespace =
        const_get_maybe_false(namespace, extension_name.upcase)

      extension_module =
        const_get_maybe_false(extension_namespace, constant_name)

      yield(extension_module) if extension_module
    end
  end

  def const_get_maybe_false(mod, name)
    # We're still heavily relying on Rails autoloading instead of zeitwerk,
    # therefore this check: `mod.const_defined?(name, false)`
    # Is not reliable, which may return false while it's defined.
    # After we moved everything over to zeitwerk we can avoid rescuing
    # NameError and just check if const_defined?
    # mod && mod.const_defined?(name, false) && mod.const_get(name, false)
    mod && mod.const_get(name, false)
  rescue NameError
    false
  end
end

Module.prepend(InjectEnterpriseEditionModule)
