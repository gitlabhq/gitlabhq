module API
  class Lint < Grape::API
    namespace :ci do
      desc 'Validation of .gitlab-ci.yml content'
      params do
        requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
      end
      post '/lint' do
        error = Gitlab::Ci::YamlProcessor.validation_message(params[:content])

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
