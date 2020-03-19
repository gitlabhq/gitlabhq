# frozen_string_literal: true

class WikiPage::MetaPolicy < BasePolicy
  delegate { @subject.project }
end
