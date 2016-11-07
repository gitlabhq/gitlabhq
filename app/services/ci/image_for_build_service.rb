module Ci
  class ImageForBuildService
    def execute(project, opts)
      ref = opts[:ref]
      sha = opts[:sha] || ref_sha(project, ref)

      pipelines = project.pipelines.where(sha: sha)

      latest_pipeline = if ref
                          pipelines.latest_for(ref)
                        else
                          pipelines.latest
                        end.first

      image_name = image_for_status(latest_pipeline.try(:status))

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
