module API
  class Lint < Grape::API
    desc 'Validation of .gitlab-ci.yml content'
    params do
      requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
    end

    namespace :ci do
      post '/lint' do
        error = Ci::GitlabCiYamlProcessor.validation_message(params[:content])

        status 200

        if error.blank?
          { status: 'valid', errors: [] }
        else
          { status: 'invalid', errors: [error] }
        end
      end
    end
  end
end
