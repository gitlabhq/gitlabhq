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
          error: [],
          jobs: []
        }

        if Ci::GitlabCiYamlProcessor.errors(params[:content]).nil?
          config_processor = Ci::GitlabCiYamlProcessor.new(params[:content])

          config_processor.builds.each do |build|
            response[:jobs].push("#{build[:name]}")
            response[:status] = 'valid'
          end
        else
          response[:error].push(Ci::GitlabCiYamlProcessor.errors(params[:content]))
          response[:status] = 'invalid'
        end

        status 200
        response
      end
    end
  end
end
