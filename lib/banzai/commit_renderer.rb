# frozen_string_literal: true

module Banzai
  module CommitRenderer
    ATTRIBUTES = [:description, :title, :full_title].freeze

    def self.render(commits, project, user = nil)
      obj_renderer = ObjectRenderer.new(user: user, default_project: project)

      ATTRIBUTES.each { |attr| obj_renderer.render(commits, attr) }
    end
  end
end
