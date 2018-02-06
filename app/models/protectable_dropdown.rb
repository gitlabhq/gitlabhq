class ProtectableDropdown
  REF_TYPES = %i[branches tags].freeze

  def initialize(project, ref_type)
    raise ArgumentError, "invalid ref type `#{ref_type}`" unless ref_type.in?(REF_TYPES)

    @project = project
    @ref_type = ref_type
  end

  # Tags/branches which are yet to be individually protected
  def protectable_ref_names
    @protectable_ref_names ||= ref_names - non_wildcard_protected_ref_names
  end

  def hash
    protectable_ref_names.map { |ref_name| { text: ref_name, id: ref_name, title: ref_name } }
  end

  private

  def refs
    @project.repository.public_send(@ref_type) # rubocop:disable GitlabSecurity/PublicSend
  end

  def ref_names
    refs.map(&:name)
  end

  def protections
    @project.public_send("protected_#{@ref_type}") # rubocop:disable GitlabSecurity/PublicSend
  end

  def non_wildcard_protected_ref_names
    protections.reject(&:wildcard?).map(&:name)
  end
end
