module Banzai
  module MentionableRenderer
    def self.render_objects(objects, attr, project, user)
      renderer = ObjectRenderer.new(project, user)

      renderer.render_objects(objects, attr)
    end
  end
end
