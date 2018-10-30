# frozen_string_literal: true

class ClusterablePresenter < Gitlab::View::Presenter::Delegated
  presents :clusterable

  def self.fabricate(clusterable, **attributes)
    presenter_class = "#{clusterable.class.name}ClusterablePresenter".constantize
    attributes_with_presenter_class = attributes.merge(presenter_class: presenter_class)

    Gitlab::View::Presenter::Factory
      .new(clusterable, attributes_with_presenter_class)
      .fabricate!
  end

  def can_create_cluster?
    can?(current_user, :create_cluster, clusterable)
  end

  def index_path
    raise NotImplementedError
  end

  def new_path
    raise NotImplementedError
  end

  def clusterable_params
    raise NotImplementedError
  end
end
