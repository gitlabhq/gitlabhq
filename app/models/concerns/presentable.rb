module Presentable
  extend ActiveSupport::Concern

  class_methods do
    def present(attributes)
      all.map { |klass_object| klass_object.present(attributes) }
    end
  end

  def present(**attributes)
    Gitlab::View::Presenter::Factory
      .new(self, attributes)
      .fabricate!
  end
end
