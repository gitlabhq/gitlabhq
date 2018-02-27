module FlashHelper
  def get_body_data_page(path)
    return unless path.empty? == false

    path_controller = Rails.application.routes.recognize_path(path)
    [path_controller[:controller].split('/'), path_controller[:action]].compact.join(':')
  end
end
