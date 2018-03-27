module QA::Page
  module Project::Job
    class Show < QA::Page::Base
      view 'app/views/projects/jobs/show.html.haml' do
        element :build_output, '.js-build-output'
      end

      def output
        css = '.js-build-output'

        wait(reload: false) do
          has_css?(css)
        end

        find(css).text
      end
    end
  end
end
