class StatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :icon, :text, :label, :group

  expose :has_details?, as: :has_details
  expose :details_path

  expose :favicon do |status|
    dir = 'ci_favicons'
    dir = File.join(dir, 'dev') if Rails.env.development?

    ActionController::Base.helpers.image_path(File.join(dir, "#{status.favicon}.ico"))
  end
end
