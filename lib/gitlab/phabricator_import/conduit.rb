# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      ApiError = Class.new(Gitlab::PhabricatorImport::BaseError)
      ResponseError = Class.new(ApiError)
    end
  end
end
