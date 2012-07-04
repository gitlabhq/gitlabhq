Dir["#{Rails.root}/lib/api/*.rb"].each {|file| require file}

module Gitlab
  class API < Grape::API
    VERSION = 'v2'
    version VERSION, :using => :path

    format :json
    error_format :json
    helpers APIHelpers

    mount Users
    mount Projects
  end
end
