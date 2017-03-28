class StatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :icon, :favicon, :text, :label, :group

  expose :has_details?, as: :has_details
  expose :details_path
end
