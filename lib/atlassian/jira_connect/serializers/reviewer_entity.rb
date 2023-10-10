# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class ReviewerEntity < Grape::Entity
        include Gitlab::Routing

        expose :name do |reviewer|
          reviewer.reviewer.name
        end
        expose :email do |reviewer|
          reviewer.reviewer.email
        end

        expose :approvalStatus do |reviewer, options|
          interaction = Users::MergeRequestInteraction.new(
            user: reviewer.reviewer, merge_request: options[:merge_request]
          )

          if interaction.approved?
            'APPROVED'
          elsif interaction.reviewed?
            'NEEDSWORK'
          else
            'UNAPPROVED'
          end
        end
      end
    end
  end
end
