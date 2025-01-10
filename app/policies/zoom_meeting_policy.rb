# frozen_string_literal: true

class ZoomMeetingPolicy < BasePolicy # rubocop:disable Gitlab/BoundedContexts, Gitlab/NamespacedClass -- required by DeclarativePolicy lookup logic
  delegate { @subject.issue }
end
