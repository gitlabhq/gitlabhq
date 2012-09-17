# Controller for viewing a repository's file structure
class TreeController < ApplicationController
  # Thrown when given an invalid path
  class InvalidPathError < StandardError; end

  include RefExtractor

  layout "project"

  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :define_tree_vars

  def show
    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end

  private

  def define_tree_vars
    @ref, @path = extract_ref(params[:id])

    @id     = File.join(@ref, @path)
    @repo   = @project.repo
    @commit = CommitDecorator.decorate(@project.commit(@ref))

    @tree = Tree.new(@commit.tree, @project, @ref, @path.gsub(/^\//, ''))
    @tree = TreeDecorator.new(@tree)

    raise InvalidPathError if @tree.invalid?

    @hex_path = Digest::SHA1.hexdigest(@path)

    @history_path = project_tree_path(@project, @id)
    @logs_path    = logs_file_project_ref_path(@project, @ref, @path)
  rescue NoMethodError, InvalidPathError
    not_found!
  end
end
