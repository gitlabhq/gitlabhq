class PagesService
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def execute
    return unless Settings.pages.enabled
    return unless data[:build_name] == 'pages'
    return unless data[:build_status] == 'success'

    PagesWorker.perform_async(:deploy, data[:build_id])
  end
end
