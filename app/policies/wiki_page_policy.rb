# frozen_string_literal: true

class WikiPagePolicy < BasePolicy
  delegate { @subject.container }

  rule { can?(:read_wiki) }.policy do
    enable :read_wiki_page
    enable :read_note
    enable :create_note
    enable :update_subscription
    enable :award_emoji
  end

  rule { ~can?(:read_wiki) }.policy do
    prevent :read_note
    prevent :create_note
    prevent :award_emoji
  end

  rule { ~can?(:read_wiki) }.policy do
    prevent :mark_note_as_internal
  end
end
