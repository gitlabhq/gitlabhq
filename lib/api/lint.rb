# frozen_string_literal: true

module API
  class Lint < Grape::API::Instance
    namespace :ci do
      desc 'Validation of .gitlab-ci.yml content'
      params do
        requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
        optional :include_merged_yaml, type: Boolean, desc: 'Whether or not to include merged CI config yaml in the response'
      end
      post '/lint' do
        result = Gitlab::Ci::YamlProcessor.new(params[:content], user: current_user).execute
        error = result.errors.first

        status 200

        response = if error.blank?
                     { status: 'valid', errors: [] }
                   else
                     { status: 'invalid', errors: [error] }
                   end

        response.tap do |response|
          response[:merged_yaml] = result.merged_yaml if params[:include_merged_yaml]
        end
      end
    end
  end
end
