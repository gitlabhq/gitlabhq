Dir["#{Rails.root}/lib/api/*.rb"].each {|file| require file}

module Gitlab
  class API < Grape::API
    version 'v3', using: :path

    rescue_from ActiveRecord::RecordNotFound do
      rack_response({'message' => '404 Not found'}.to_json, 404)
    end

    format :json
    error_format :json
    helpers APIHelpers

    mount Users
    mount Projects
    mount Issues
    mount Milestones
    mount Session
    mount MergeRequests
    mount Notes
  end
end
