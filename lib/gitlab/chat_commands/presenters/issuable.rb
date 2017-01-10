module Gitlab::ChatCommands::Presenters
  class Issuable < Gitlab::ChatCommands::Presenters::Base
    private

    def project
      @resource.project
    end

    def author
      @resource.author
    end

    def fields
      [
        {
          title: "Assignee",
          value: @resource.assignee ? @resource.assignee.name : "_None_",
          short: true
        },
        {
          title: "Milestone",
          value: @resource.milestone ? @resource.milestone.title : "_None_",
          short: true
        },
        {
          title: "Labels",
          value: @resource.labels.any? ? @resource.label_names : "_None_",
          short: true
        }
      ]
    end
  end
end
