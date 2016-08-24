module Ci
  module API
    class Lint < Grape::API
      resource :lint do
        post do
          status 200
          params do
            requires :content, type: String, desc: 'content of .gitlab-ci.yml'
          end

          begin
            response = {
              status: '',
              errors: [],
              jobs: []
            }

            config_processor = Ci::GitlabCiYamlProcessor.new(params[:content])

            config_processor.builds.each do |build|
              response[:jobs].push("#{build[:name]}")
              response[:status] = 'valid'
            end

            response

          rescue Ci::GitlabCiYamlProcessor::ValidationError, Psych::SyntaxError => e
            status 200
            response[:errors].push(e.message)
            response[:status] = 'invalid'

            response
          end
        end
      end
    end
  end
end
