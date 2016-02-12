module Ci
  class ImageForBuildService
    def execute(project, opts)
      sha = opts[:sha] || ref_sha(project, opts[:ref])

      commit = project.ci_commits.ordered.find_by(sha: sha)
      image_name = image_for_commit(commit)

      image_path = Rails.root.join('public/ci', image_name)
      OpenStruct.new(path: image_path, name: image_name)
    end

    private

    def ref_sha(project, ref)
      project.commit(ref).try(:sha) if ref
    end

    def image_for_commit(commit)
      return 'build-unknown.svg' unless commit
      'build-' + commit.status + ".svg"
    end
  end
end
