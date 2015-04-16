module FixturesDevelopmentHelper
  class << self
    def template_project
      @template_project ||= Project.
        find_with_namespace('gitlab-org/gitlab-test')
    end
  end
end
