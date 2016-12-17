class ReactiveCachingWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(class_name, id)
    klass = begin
      Kernel.const_get(class_name)
    rescue NameError
      nil
    end
    return unless klass

    klass.find_by(id: id).try(:exclusively_update_reactive_cache!)
  end
end
