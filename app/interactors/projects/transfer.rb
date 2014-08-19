# Projects::Transfer interactor
#
# Used for transfer project to another namespace
#
# Ex.
#   # Move @project to @namespace with ID 17 by @user
#   Projects::Transfer.perform(project: project,
#                              user:    user,
#                              params:  { namespace_id: 17 })
module Projects
  class Transfer
    include Interactor::Organizer

    def setup
      context.fail!(message: 'Invalid user') if context[:user].blank?
      context.fail!(message: 'Invalid proejct') if context[:project].blank?
      context.fail!(message: 'Invalid params') if context[:params].blank?

      namespace_id = context[:params][:namespace]
      context[:namespace] = Namespace.find_by(id: namespace_id)

      context.fail!(message: 'Invalid namespace') if context[:params].blank?

      # User can manage target namespace
      unless allowed_transfer?(context[:user],
                               context[:project],
                               context[:namespace])
        context.fail!(message: 'User has not permossion in target namespace')
      end

      # No project with same 'path' in target namespace
      if Project.where(path: context[:project].path, namespace_id: namespace_id).present?
        context.fail!('Project with same path in target namespace already exists')
      end
    end

    organize [
      Projects::RemoveSatellite,
      Projects::TransferWiki,
      Projects::TransferProject,
      Projects::EnsureSatelliteExists,
      Projects::ResetEventsCache
    ]

    private

    def allowed_transfer?(user, project, namespace)
      namespace && namespace.id != project.namespace_id &&
        can?(user, :change_namespace, project) &&
        can?(user, :create_projects, namespace)
    end
  end
end
