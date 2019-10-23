# frozen_string_literal: true

class Projects::WikiDirectoriesController < Projects::ApplicationController
  include ProjectWikiActions

  def self.local_prefixes
    [controller_path, 'shared/wiki']
  end

  def show
    @wiki_dir = find_dir || WikiDirectory.new(params[:id])

    return render('empty') if @wiki_dir.empty?

    @wiki_entries = @wiki_pages = Kaminari
      .paginate_array(@wiki_dir.pages)
      .page(params[:page])

    render 'show'
  end

  private

  def find_dir
    dir_params = params.permit(:id, :sort, :direction).dup.tap do |h|
      Gitlab::Utils.allow_hash_values(h, sort_params_config[:allowed])
    end

    project_wiki.find_dir(dir_params[:id], dir_params[:sort], dir_params[:direction])
  end
end
