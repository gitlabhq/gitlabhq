# frozen_string_literal: true

class GroupLabelPolicy < BasePolicy
  delegate { @subject.parent_container }
end
