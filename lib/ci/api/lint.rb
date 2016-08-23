module Ci
  module API
    class Lint < Grape::API
      before { authenticate! }

      resources :lint do

        post do
          begin
            response = {}
            @content = params[:content]

            if @content
              @config_processor = Ci::GitlabCiYamlProcessor.new(@content)
              @stages = @config_processor.stages
              @builds = @config_processor.builds

              response = {
                content: @content,
                status: "syntax is correct"
              }

              stage_builds = @stages.each do |stage|
                response["#{stage}"] = @builds.select { |build| build[:stage] == stage }
              end
            else
              render_api_error!("Please provide content of .gitlab-ci.yml", 400)
            end

            response

          rescue Ci::GitlabCiYamlProcessor::ValidationError, Psych::SyntaxError => e
            error!({ content: @content, status: "syntax is incorrect", message: e.message })
          end
        end
      end
    end
  end
end
