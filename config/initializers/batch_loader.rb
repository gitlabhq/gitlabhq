# frozen_string_literal: true

Rails.application.config.middleware.use(BatchLoader::Middleware)

# Disables replace_methods by default.
# See https://github.com/exAspArk/batch-loader#replacing-methods for more information.
module BatchLoaderWithoutMethodReplacementByDefault
  def batch(replace_methods: false, **kw_args, &batch_block)
    super
  end
end

BatchLoader.prepend(BatchLoaderWithoutMethodReplacementByDefault)
