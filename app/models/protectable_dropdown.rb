# frozen_string_literal: true

class ProtectableDropdown
  REF_TYPES = %i[branches tags].freeze
  REF_NAME_METHODS = {
    branches: :branch_names,
    tags: :tag_names
  }.freeze

  def initialize(project, ref_type, ref_names: nil)
    raise ArgumentError, "invalid ref type `#{ref_type}`" unless ref_type.in?(REF_TYPES)

    @project = project
    @ref_type = ref_type
    @ref_names = ref_names.presence || get_ref_names
  end

  # Tags/branches which are yet to be individually protected
  def protectable_ref_names
    return [] if @project.empty_repo?

    @protectable_ref_names ||= ref_names - non_wildcard_protected_ref_names
  end

  def array
    protectable_ref_names.map { |ref_name| { text: ref_name, id: ref_name, title: ref_name } }
  end

  private

  attr_reader :ref_names

  def get_ref_names
    @project.repository.public_send(ref_name_method) # rubocop:disable GitlabSecurity/PublicSend
  end

  def ref_name_method
    REF_NAME_METHODS[@ref_type]
  end

  def protections
    @project.public_send("protected_#{@ref_type}") # rubocop:disable GitlabSecurity/PublicSend
  end

  def non_wildcard_protected_ref_names
    protections.reject(&:wildcard?).map(&:name)
  end
end
