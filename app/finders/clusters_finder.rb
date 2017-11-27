class ClustersFinder
  def initialize(project, user, scope)
    @project = project
    @user = user
    @scope = scope
  end

  def execute
    clusters = case @scope
               when :all
                 @project.clusters
               when :enabled
                 @project.clusters.enabled
               when :disabled
                 @project.clusters.disabled
               end
    clusters.map { |cluster| cluster.present(current_user: @user) }
  end
end
