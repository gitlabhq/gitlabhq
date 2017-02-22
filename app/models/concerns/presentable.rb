module Presentable
  def present(**attributes)
    Gitlab::View::Presenter::Factory
      .new(self, attributes)
      .fabricate!
  end
end
