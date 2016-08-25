module API
  class Lint < Grape::API
    resource :lint do
      params do
        requires :content, type: String, desc: 'content of .gitlab-ci.yml'
      end

      desc 'Validation of .gitlab-ci.yml content'
      post do
        response = {
          status: '',
          errors: [],
          jobs: []
        }

        if Ci::GitlabCiYamlProcessor.validate(@content) != "valid"
          status 200
          response[:errors].push(e.message)
          response[:status] = 'invalid'

          response
        end

        config_processor = Ci::GitlabCiYamlProcessor.new(params[:content])

        config_processor.builds.each do |build|
          response[:jobs].push("#{build[:name]}")
          response[:status] = 'valid'
        end

        status 200
        response
      end
    end
  end
end
