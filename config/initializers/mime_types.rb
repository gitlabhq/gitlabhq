# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register_alias "text/plain", :diff
Mime::Type.register_alias "text/plain", :patch
Mime::Type.register_alias "text/html",  :markdown
Mime::Type.register_alias "text/html",  :md

Mime::Type.register "video/mp4",  :mp4, [], [:m4v, :mov]
Mime::Type.register "video/webm", :webm
Mime::Type.register "video/ogg",  :ogv

middlewares = Gitlab::Application.config.middleware
middlewares.swap(ActionDispatch::ParamsParser, ActionDispatch::ParamsParser, {
  Mime::Type.lookup('application/vnd.git-lfs+json') => lambda do |body|
    ActiveSupport::JSON.decode(body)
  end
})
