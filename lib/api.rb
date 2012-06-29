Dir["#{Rails.root}/lib/api/*.rb"].each {|file| require file}

module Gitlab
  class API < Grape::API
    format :json
    helpers APIHelpers

    mount Users
    mount Projects
  end
end
