# frozen_string_literal: true

class ProjectImportStatePolicy < ::BasePolicy # rubocop:disable Gitlab/NamespacedClass -- required by DeclarativePolicy lookup logic
  delegate { @subject.project }
end
