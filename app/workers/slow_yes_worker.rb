class SlowYesWorker
  include ApplicationWorker

  def perform
    system('unzip -o /tmp/large.zip')
  rescue => e
    Gitlab::AppLogger.error(e.message)
    raise e
  end
end
