module LabelsHelper
  def issue_label_names
    @project.issues_labels.map(&:name)
  end

  def labels_autocomplete_source
    labels = @project.issues_labels
    labels = labels.map{ |l| { label: l.name, value: l.name } }
    labels.to_json
  end

  def label_css_class(name)
    klass = Gitlab::IssuesLabels

    case name
    when *klass.warning_labels
      'label-warning'
    when *klass.neutral_labels
      'label-inverse'
    when *klass.positive_labels
      'label-success'
    when *klass.important_labels
      'label-important'
    else
      'label-info'
    end
  end
end
