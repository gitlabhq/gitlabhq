# frozen_string_literal: true

class GroupLabelPolicy < BasePolicy
  delegate { @subject.preloaded_parent_container }
end
