class UpdateMergeRequestsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(project_id, user_id, oldrev, newrev, ref)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    # TODO: remove this benchmarking when we have rich logging
    time = Benchmark.measure do
      MergeRequests::RefreshService.new(project, user).execute(oldrev, newrev, ref)
    end

    log_args = ["elapsed=#{time.real}"]
    method(__method__).parameters.map do |_, p|
      pname = p.to_s
      log_args << [pname, binding.local_variable_get(pname)].join('=')
    end

    Rails.logger.info("UpdateMergeRequestsWorker#perform #{log_args.join(',')}")
  end
end
