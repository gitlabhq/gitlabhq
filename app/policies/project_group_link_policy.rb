# frozen_string_literal: true

class ProjectGroupLinkPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.project }
end
