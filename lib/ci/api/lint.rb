module Ci
  module API
    class Lint < Grape::API
      before { authenticate! }

      resources :lint do
        post do
          content = params[:content]

          if content
            config_processor = Ci::GitlabCiYamlProcessor.new(content)
            stages = config_processor.stages
            builds = config_processor.builds
            status = true

            response = { status: status, stages: stages, builds: builds }
          end

          response
        end
      end
    end
  end
end
