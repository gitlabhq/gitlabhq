require 'flipper/middleware/memoizer'

Rails.application.config.middleware.use Flipper::Middleware::Memoizer,
  lambda { Feature.flipper }
