module Banzai
  module CommitDescriptionRenderer
    def self.render(commit_descriptions, project, user = nil)
      ObjectRenderer.new(project, user).render(commit_descriptions, :commit_description)
    end
  end
end
