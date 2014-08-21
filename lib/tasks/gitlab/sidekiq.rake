namespace :gitlab do
  namespace :sidekiq do
    QUEUE = 'queue:post_receive'

    desc 'Drop all Sidekiq PostReceive jobs for a given project'
    task :drop_post_receive , [:project] => :environment do |t, args|
      unless args.project.present?
        abort "Please specify the project you want to drop PostReceive jobs for:\n  rake gitlab:sidekiq:drop_post_receive[group/project]"
      end
      project_path = Project.find_with_namespace(args.project).repository.path_to_repo

      Sidekiq.redis do |redis|
        unless redis.exists(QUEUE)
          abort "Queue #{QUEUE} is empty"
        end

        temp_queue = "#{QUEUE}_#{Time.now.to_i}"
        redis.rename(QUEUE, temp_queue)

        # At this point, then post_receive queue is empty. It may be receiving
        # new jobs already. We will repopulate it with the old jobs, skipping the
        # ones we want to drop.
        dropped = 0
        while (job = redis.lpop(temp_queue)) do
          if repo_path(job) == project_path
            dropped += 1
          else
            redis.rpush(QUEUE, job)
          end
        end
        # The temp_queue will delete itself after we have popped all elements
        # from it

        puts "Dropped #{dropped} jobs containing #{project_path} from #{QUEUE}"
      end
    end

    def repo_path(job)
      job_args = JSON.parse(job)['args']
      if job_args
        job_args.first
      else
        nil
      end
    end
  end
end
