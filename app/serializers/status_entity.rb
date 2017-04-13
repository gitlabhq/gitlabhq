class StatusEntity < Grape::Entity
  include RequestAwareEntity
  include CiStatusHelper

  format_with(:status_favicon_path) do |favicon_name|
    ci_status_favicon_path(favicon_name)
  end

  expose :icon, :text, :label, :group

  expose :has_details?, as: :has_details
  expose :details_path

  expose :favicon, format_with: :status_favicon_path
end
