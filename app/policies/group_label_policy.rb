# frozen_string_literal: true

class GroupLabelPolicy < BasePolicy
  delegate { @subject.group }
end
