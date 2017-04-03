class ProtectableDropdown
  def initialize(project, ref_type)
    @project = project
    @ref_type = ref_type
  end

  # Tags/branches which are yet to be individually protected
  def protectable_ref_names
    non_wildcard_protections = protections.reject(&:wildcard?)
    refs.map(&:name) - non_wildcard_protections.map(&:name)
  end

  def hash
    protectable_ref_names.map { |ref_name| { text: ref_name, id: ref_name, title: ref_name } }
  end

  private

  def refs
    @project.repository.public_send(@ref_type)
  end

  def protections
    @project.public_send("protected_#{@ref_type}")
  end
end
