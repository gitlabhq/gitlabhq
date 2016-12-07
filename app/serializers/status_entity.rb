class StatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :icon, :text, :label, :title

  expose :has_details?, as: :has_details
  expose :details_path
end
