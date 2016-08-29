module API
  class Lint < Grape::API
    desc 'Validation of .gitlab-ci.yml content'
    params do
      requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
    end

    post 'ci/lint' do
      error = Ci::GitlabCiYamlProcessor.validation_message(params[:content])
      response = {
        status: '',
        error: ''
      }

      if error.blank?
        response[:status] = 'valid'
      else
        response[:error] = error
        response[:status] = 'invalid'
      end

      status 200
      response
    end
  end
end
