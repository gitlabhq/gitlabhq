# frozen_string_literal: true

class GroupGroupLinkPolicy < ::BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.group }
end
