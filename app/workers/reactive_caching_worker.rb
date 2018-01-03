class ReactiveCachingWorker
  include ApplicationWorker

  def perform(class_name, id, *args)
    klass = begin
      Kernel.const_get(class_name)
    rescue NameError
      nil
    end
    return unless klass

    klass.find_by(id: id).try(:exclusively_update_reactive_cache!, *args)
  end
end
