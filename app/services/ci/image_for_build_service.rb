module Ci
  class ImageForBuildService
    def execute(project, opts)
      sha = opts[:sha] || ref_sha(project, opts[:ref])

      pipelines = project.pipelines.where(sha: sha)
      pipelines = pipelines.where(ref: opts[:ref]) if opts[:ref]
      image_name = image_for_status(pipelines.status)

      image_path = Rails.root.join('public/ci', image_name)
      OpenStruct.new(path: image_path, name: image_name)
    end

    private

    def ref_sha(project, ref)
      project.commit(ref).try(:sha) if ref
    end

    def image_for_status(status)
      status ||= 'unknown'
      'build-' + status + ".svg"
    end
  end
end
