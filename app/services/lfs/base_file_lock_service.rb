# frozen_string_literal: true

module Lfs # rubocop:disable Gitlab/BoundedContexts -- These classes already exist so need some work before possible to move
  class BaseFileLockService < BaseService
  end
end

Lfs::BaseFileLockService.prepend_mod
