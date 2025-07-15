# frozen_string_literal: true

class WikiPagePolicy < BasePolicy
  delegate { @subject.container }

  overrides :read_note, :create_note

  condition(:planner_or_reporter_access) do
    can?(:reporter_access) || can?(:planner_access)
  end

  rule { can?(:read_wiki) }.policy do
    enable :read_wiki_page
    enable :read_note
    enable :create_note
    enable :update_subscription
  end

  rule { can?(:read_wiki) & planner_or_reporter_access }.policy do
    enable :mark_note_as_internal
  end
end
