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
    result = mod && mod.const_get(name, false)

    if result.name == "#{mod}::#{name}"
      result
    else
      # This may hit into a Rails issue that when we try to load
      # `EE::API::Appearance`, Rails might load `::Appearance` the first time
      # when `mod.const_get(name, false)` is called if `::Appearance` is not
      # loaded yet. This can be demonstrated as the following:
      #
      #     EE.const_get('API::Appearance', false) # => Appearance
      #     EE.const_get('API::Appearance', false) # => raise NameError
      #
      # Getting a `NameError` is what we're expecting here, because
      # `EE::API::Appearance` doesn't exist.
      #
      # This is because Rails will attempt to load constants from all the
      # parent namespaces, and if it finds one it'll load it and return it.
      # However, the second time when it's called, since the top-level class
      # is already loaded, then Rails will skip this process. This weird
      # behaviour can be worked around by calling this the second time.
      # The particular line is at:
      # https://github.com/rails/rails/blob/v6.1.3.2/activesupport/lib/active_support/dependencies.rb#L569-L570
      mod.const_get(name, false)
    end
  rescue NameError
    false
  end
end

Module.prepend(InjectEnterpriseEditionModule)
