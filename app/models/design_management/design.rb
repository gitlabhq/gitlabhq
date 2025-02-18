# frozen_string_literal: true

module DesignManagement
  class Design < ApplicationRecord
    include AtomicInternalId
    include Importable
    include Import::HasImportSource
    include Noteable
    include Gitlab::FileTypeDetection
    include Gitlab::Utils::StrongMemoize
    include Referable
    include Mentionable
    include WhereComposite
    include RelativePositioning
    include Todoable
    include Participable
    include CacheMarkdownField
    include Subscribable
    include EachBatch

    cache_markdown_field :description

    belongs_to :project, inverse_of: :designs
    belongs_to :issue

    has_many :actions
    has_many :versions, through: :actions, class_name: 'DesignManagement::Version', inverse_of: :designs
    has_many :authors, -> { distinct }, through: :versions, class_name: 'User'
    # This is a polymorphic association, so we can't count on FK's to delete the
    # data
    has_many :notes, as: :noteable, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
    has_many :user_mentions, class_name: 'DesignUserMention', dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    has_internal_id :iid, scope: :project, presence: true,
      hook_names: %i[create update], # Deal with old records
      track_if: -> { !importing? }

    validates :project, :filename, presence: true
    validates :issue, presence: true, unless: :importing?
    validates :filename, uniqueness: { scope: :issue_id }, length: { maximum: 255 }
    validates :description, length: { maximum: Gitlab::Database::MAX_TEXT_SIZE_LIMIT }
    validate :validate_file_is_image

    alias_attribute :title, :filename

    participant :authors
    participant :notes_with_associations

    # Pre-fetching scope to include the data necessary to construct a
    # reference using `to_reference`.
    scope :for_reference, -> { includes(issue: [{ namespace: :project }, { project: [:route, :namespace] }]) }

    # A design can be uniquely identified by issue_id and filename
    # Takes one or more sets of composite IDs of the form:
    # `{issue_id: Integer, filename: String}`.
    #
    # @see WhereComposite::where_composite
    #
    # e.g:
    #
    #   by_issue_id_and_filename(issue_id: 1, filename: 'homescreen.jpg')
    #   by_issue_id_and_filename([]) # returns DesignManagement::Design.none
    #   by_issue_id_and_filename([
    #     { issue_id: 1, filename: 'homescreen.jpg' },
    #     { issue_id: 2, filename: 'homescreen.jpg' },
    #     { issue_id: 1, filename: 'menu.png' }
    #   ])
    #
    scope :by_issue_id_and_filename, ->(composites) do
      where_composite(%i[issue_id filename], composites)
    end

    # Find designs visible at the given version
    #
    # @param version [nil, DesignManagement::Version]:
    #   the version at which the designs must be visible
    #   Passing `nil` is the same as passing the most current version
    #
    # Restricts to designs
    # - created at least *before* the given version
    # - not deleted as of the given version.
    #
    # As a query, we ascertain this by finding the last event prior to
    # (or equal to) the cut-off, and seeing whether that version was a deletion.
    scope :visible_at_version, ->(version) do
      deletion = DesignManagement::Action.events[:deletion]
      designs = arel_table
      actions = DesignManagement::Action
        .most_recent.up_to_version(version)
        .arel.as('most_recent_actions')

      join = designs.join(actions)
        .on(actions[:design_id].eq(designs[:id]))

      joins(join.join_sources).where(actions[:event].not_eq(deletion))
    end

    scope :ordered, -> do
      # We need to additionally sort by `id` to support keyset pagination.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17788/diffs#note_230875678
      order(:relative_position, :id)
    end

    scope :in_creation_order, -> { reorder(:id) }

    scope :with_filename, ->(filenames) { where(filename: filenames) }
    scope :on_issue, ->(issue) { where(issue_id: issue) }

    # Scope called by our REST API to avoid N+1 problems
    scope :with_api_entity_associations, -> { preload(:issue) }

    # A design is current if the most recent event is not a deletion
    scope :current, -> { visible_at_version(nil) }

    def self.relative_positioning_query_base(design)
      default_scoped.on_issue(design.issue_id)
    end

    def self.relative_positioning_parent_column
      :issue_id
    end

    def status
      if new_design?
        :new
      elsif deleted?
        :deleted
      else
        :current
      end
    end

    def deleted?
      most_recent_action&.deletion?
    end

    # A design is visible_in? a version if:
    #   * it was created before that version
    #   * the most recent action before the version was not a deletion
    def visible_in?(version)
      map = strong_memoize(:visible_in) do
        Hash.new do |h, k|
          h[k] = self.class.visible_at_version(k).where(id: id).exists?
        end
      end

      map[version]
    end

    def most_recent_action
      strong_memoize(:most_recent_action) { actions.ordered.last }
    end

    # A reference for a design is the issue reference, indexed by the filename
    # with an optional infix when full.
    #
    # e.g.
    #   #123[homescreen.png]
    #   other-project#72[sidebar.jpg]
    #   #38/designs[transition.gif]
    #   #12["filename with [] in it.jpg"]
    def to_reference(from = nil, full: false)
      infix = full ? '/designs' : ''
      safe_name = Sanitize.fragment(filename)

      "#{issue.to_reference(from, full: full)}#{infix}[#{safe_name}]"
    end

    def self.reference_pattern
      # no-op: We only support link_reference_pattern parsing
    end

    def self.link_reference_pattern
      @link_reference_pattern ||= begin
        path_segment = %r{issues/#{Gitlab::Regex.issue}/designs}
        ext = Regexp.new(Regexp.union(SAFE_IMAGE_EXT + DANGEROUS_IMAGE_EXT).source, Regexp::IGNORECASE)
        valid_char = %r{[[:word:]\.\-\+]}
        filename_pattern = %r{
          (?<url_filename> #{valid_char}+ \. #{ext})
        }x

        compose_link_reference_pattern(path_segment, filename_pattern)
      end
    end

    def self.build_full_path(issue, design)
      File.join(DesignManagement.designs_directory, "issue-#{issue.iid}", design.filename)
    end

    def self.to_ability_name
      'design'
    end

    def new_design?
      strong_memoize(:new_design) { actions.none? }
    end

    def full_path
      @full_path ||= self.class.build_full_path(issue, self)
    end

    def diff_refs
      strong_memoize(:diff_refs) { head_version&.diff_refs }
    end

    def clear_version_cache
      [versions, actions].each(&:reset)
      %i[new_design diff_refs head_sha visible_in most_recent_action].each do |key|
        clear_memoization(key)
      end
    end

    def repository
      project.design_repository
    end

    def user_notes_count
      user_notes_count_service.count
    end

    def after_note_changed(note)
      user_notes_count_service.delete_cache unless note.system?
    end
    alias_method :after_note_created,   :after_note_changed
    alias_method :after_note_destroyed, :after_note_changed

    # Part of the interface of objects we can create events about
    def resource_parent
      project
    end

    def notes_with_associations
      notes.includes(:author)
    end

    private

    def head_version
      strong_memoize(:head_sha) { versions.ordered.first }
    end

    def allow_dangerous_images?
      Feature.enabled?(:design_management_allow_dangerous_images, project)
    end

    def valid_file_extensions
      allow_dangerous_images? ? (SAFE_IMAGE_EXT + DANGEROUS_IMAGE_EXT) : SAFE_IMAGE_EXT
    end

    def validate_file_is_image
      unless image? || (dangerous_image? && allow_dangerous_images?)
        message = _('does not have a supported extension. Only %{extension_list} are supported') % {
          extension_list: valid_file_extensions.to_sentence
        }
        errors.add(:filename, message)
      end
    end

    def user_notes_count_service
      strong_memoize(:user_notes_count_service) do
        DesignManagement::DesignUserNotesCountService.new(self) # rubocop: disable CodeReuse/ServiceClass
      end
    end
  end
end
