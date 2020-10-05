# frozen_string_literal: true

class WikiPolicy < ::BasePolicy
  # Wiki policies are delegated to their container objects (Project or Group)
  delegate { subject.container }
end
