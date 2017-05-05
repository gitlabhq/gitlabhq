class StatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :icon, :text, :label, :group

  expose :has_details?, as: :has_details
  expose :details_path

  expose :favicon do |status|
    ActionController::Base.helpers.image_path(File.join('ci_favicons', "#{status.favicon}.ico"))
  end
end
