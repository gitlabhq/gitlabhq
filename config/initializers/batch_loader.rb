# frozen_string_literal: true

Rails.application.config.middleware.use(BatchLoader::Middleware)

# Disables replace_methods by default.
# See https://github.com/exAspArk/batch-loader#replacing-methods for more information.
module BatchLoaderWithoutMethodReplacementByDefault
  def batch(replace_methods: false, **kw_args, &batch_block)
    super
  end

  private

  # In Ruby, `Array#flatten` recursively calls `#to_ary` on each element.
  # If an element is a `BatchLoader` instance, and `to_ary` is not defined,
  # Ruby will invoke `method_missing`, causing `BatchLoader` to delegate the call
  # to its underlying `ActiveRecord` object.
  #
  # However, since `ActiveRecord::Base` defines `to_ary` as a private method,
  # the delegation attempt results in a `NoMethodError: private method `to_ary' called...
  #
  # This ensures method_missing never calls public_send on a private method, avoiding crashes.
  def respond_to_missing?(method_name, include_private = false)
    return true if __sync!.respond_to?(method_name, false)

    super
  end
end

BatchLoader.prepend(BatchLoaderWithoutMethodReplacementByDefault)
