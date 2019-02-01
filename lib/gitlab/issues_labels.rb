# frozen_string_literal: true

module Gitlab
  class IssuesLabels
    class << self
      def generate(project)
        red = '#d9534f'
        yellow = '#f0ad4e'
        blue = '#428bca'
        green = '#5cb85c'

        labels = [
          { title: "bug", color: red },
          { title: "critical", color: red },
          { title: "confirmed", color: red },
          { title: "documentation", color: yellow },
          { title: "support", color: yellow },
          { title: "discussion", color: blue },
          { title: "suggestion", color: blue },
          { title: "enhancement", color: green }
        ]

        labels.each do |params|
          ::Labels::FindOrCreateService.new(nil, project, params).execute(skip_authorization: true)
        end
      end
    end
  end
end
