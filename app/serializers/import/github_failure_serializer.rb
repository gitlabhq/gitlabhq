# frozen_string_literal: true

module Import
  class GithubFailureSerializer < BaseSerializer
    include WithPagination

    entity Import::GithubFailureEntity
  end
end
