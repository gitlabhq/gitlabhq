module Ci
  class Variable
    class Presenter < Gitlab::View::Presenter::Simple
      presents :variable
    end
  end
end
