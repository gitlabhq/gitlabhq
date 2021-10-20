# frozen_string_literal: true

class TagsFinder < GitRefsFinder
  def initialize(repository, params)
    super(repository, params)
  end

  def execute
    tags = repository.tags_sorted_by(sort)

    [by_search(tags), nil]
  rescue Gitlab::Git::CommandError => e
    [[], e]
  end
end
