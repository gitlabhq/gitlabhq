# frozen_string_literal: true

class ReadmeBlob < SimpleDelegator
  include BlobActiveModel

  attr_reader :repository

  def initialize(blob, repository)
    @repository = repository

    super(blob)
  end

  def rendered_markup
    repository.rendered_readme
  end
end
