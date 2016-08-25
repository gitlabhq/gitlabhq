module API
  class Lint < Grape::API
    resource :lint do
      params do
        requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
      end

      desc 'Validation of .gitlab-ci.yml content'
      post do
        response = {
          status: '',
          errors: [],
          jobs: []
        }

        if Ci::GitlabCiYamlProcessor.errors(@content) != nil
          status 200
          response[:errors].push(Ci::GitlabCiYamlProcessor.errors(@content))
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
