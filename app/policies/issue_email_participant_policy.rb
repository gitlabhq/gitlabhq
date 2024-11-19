# frozen_string_literal: true

# Model is not in a product domain namespace.
class IssueEmailParticipantPolicy < BasePolicy # rubocop:disable Gitlab/BoundedContexts, Gitlab/NamespacedClass -- reason above
  delegate { @subject.issue }
end
