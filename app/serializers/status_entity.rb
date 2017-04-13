class StatusEntity < Grape::Entity
  include RequestAwareEntity

  format_with(:status_favicon_path) do |favicon_name|
    ci_status_favicon_path(favicon_name)
  end

  expose :icon, :text, :label, :group

  expose :has_details?, as: :has_details
  expose :details_path

  expose :favicon do |status|
    ActionController::Base.helpers.image_path(File.join('ci_favicons', "#{status.favicon}.ico"))
  end
end
