# frozen_string_literal: true

module Ci
  class CodequalityMrDiffEntity < Grape::Entity
    expose :files
  end
end
