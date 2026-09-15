# frozen_string_literal: true

class ProtectableDropdown
  MAX_EXCLUDE_PATTERNS = 100
  REF_TYPES = %i[branches tags].freeze
  REF_NAME_METHODS = {
    branches: :branch_names,
    tags: :tag_names
  }.freeze

  def initialize(project, ref_type, ref_names: nil)
    raise ArgumentError, "invalid ref type `#{ref_type}`" unless ref_type.in?(REF_TYPES)

    @project = project
    @ref_type = ref_type
    @ref_names = ref_names.presence
  end

  def protectable_ref_names
    return [] if @project.empty_repo?

    @protectable_ref_names ||= ref_names - non_wildcard_protected_ref_names
  end

  def paginated_protectable_ref_names(limit:, page_token: nil, search: nil)
    return { names: [], next_cursor: nil } if @project.empty_repo?

    finder = Gitlab::Git::Finders::RefsFinder.new(
      @project.repository,
      ref_type: @ref_type,
      search: search,
      per_page: limit,
      page_token: page_token,
      ignore_case: search.present?,
      exclude_ref_names: non_wildcard_protected_ref_names.first(MAX_EXCLUDE_PATTERNS)
    )

    refs = finder.execute
    names = refs.map(&:name)

    { names: names, next_cursor: finder.next_cursor }
  end

  def array
    protectable_ref_names.map { |ref_name| { text: ref_name, id: ref_name, title: ref_name } }
  end

  private

  def ref_names
    @ref_names ||= get_ref_names
  end

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
    protections.order(:id).reject(&:wildcard?).map(&:name)
  end
end
