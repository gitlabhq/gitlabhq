# frozen_string_literal: true

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

Mime::Type.unregister :json
Mime::Type.register 'application/json', :json, [LfsRequest::CONTENT_TYPE, 'application/json']

Mime::Type.register 'image/x-icon', :ico
