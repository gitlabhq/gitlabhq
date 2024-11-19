# frozen_string_literal: true

class WikiPagePolicy < BasePolicy
  delegate { @subject.container }

  overrides :read_note, :create_note

  rule { can?(:read_wiki) }.policy do
    enable :read_wiki_page
    enable :read_note
    enable :create_note
  end
end
