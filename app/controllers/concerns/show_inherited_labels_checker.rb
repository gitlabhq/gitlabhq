# frozen_string_literal: true

module ShowInheritedLabelsChecker
  extend ActiveSupport::Concern

  private

  def show_inherited_labels?(include_ancestor_groups)
    Feature.enabled?(:show_inherited_labels, @project || @group, default_enabled: true) || include_ancestor_groups # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
