module Ci
  class ImageForBuildService
    def execute(project, params)
      sha = params[:sha]
      sha ||=
        if params[:ref]
          project.gl_project.commit(params[:ref]).try(:sha)
        end

      commit = project.commits.ordered.find_by(sha: sha)
      image_name = image_for_commit(commit)

      image_path = Rails.root.join('public/ci', image_name)

      OpenStruct.new(
        path: image_path,
        name: image_name
      )
    end

    private

    def image_for_commit(commit)
      return 'build-unknown.svg' unless commit

      'build-' + commit.status + ".svg"
    end
  end
end
