class SystemHook < WebHook
  
  def async_execute(data)
    Resque.enqueue(SystemHookWorker, id, data)
  end

  def self.all_hooks_fire(data)
    SystemHook.all.each do |sh|
      sh.async_execute data
    end
  end
  
end
