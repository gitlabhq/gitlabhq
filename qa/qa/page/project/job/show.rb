module QA::Page
  module Project::Job
    class Show < QA::Page::Base
      def output
        css = '.js-build-output'
        wait { has_css?(css) }
        find(css).text
      end
    end
  end
end
