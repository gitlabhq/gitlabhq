# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register_alias "text/plain", :diff
Mime::Type.register_alias "text/plain", :patch
Mime::Type.register_alias 'text/html',  :markdown
Mime::Type.register_alias 'text/html',  :md
#Mime::Type.unregister :json
Mime::Type.register_alias 'application/vnd.docker.distribution.manifest.v1+prettyjws', :json
#Mime::Type.register 'application/json', :json, %w( text/plain text/x-json application/jsonrequest )

ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime::Type.lookup('application/vnd.docker.distribution.manifest.v1+prettyjws')]=lambda do |body|
  JSON.parse(body)
end
