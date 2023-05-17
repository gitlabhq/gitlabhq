# frozen_string_literal: true

class LabelPresenter < Gitlab::View::Presenter::Delegated
  presents ::Label, as: :label
  delegate :name, :full_name, to: :label_subject, prefix: :subject, allow_nil: true

  def edit_path
    case label
    when GroupLabel then edit_group_label_path(label.group, label)
    when ProjectLabel then edit_project_label_path(label.project, label)
    else edit_admin_label_path(label)
    end
  end

  def text_color_class
    "gl-label-text-#{label.color.contrast.luminosity}"
  end

  def destroy_path
    case label
    when GroupLabel then group_label_path(label.group, label)
    when ProjectLabel then project_label_path(label.project, label)
    else admin_label_path(label)
    end
  end

  def filter_path(type: :issue)
    case context_subject
    when Group
      send( # rubocop:disable GitlabSecurity/PublicSend
        "#{type.to_s.pluralize}_group_path",
        context_subject,
        label_name: [label.name]
      )
    when Project
      send( # rubocop:disable GitlabSecurity/PublicSend
        "namespace_project_#{type.to_s.pluralize}_path",
        context_subject.namespace,
        context_subject,
        label_name: [label.name]
      )
    end
  end

  def can_subscribe_to_label_in_different_levels?
    issuable_subject.is_a?(Project) && label.is_a?(GroupLabel)
  end

  def project_label?
    label.is_a?(ProjectLabel)
  end

  def label_subject
    @label_subject ||= label.subject if label.respond_to?(:subject)
  end

  private

  def context_subject
    issuable_subject || label.try(:subject)
  end
end

LabelPresenter.prepend_mod_with('LabelPresenter')
