module EE
  module Epic
    extend ActiveSupport::Concern

    prepended do
      include NonatomicInternalId
      include Issuable
      include Noteable
      include Referable
      include Awardable

      belongs_to :assignee, class_name: "User"
      belongs_to :group

      has_many :epic_issues

      validates :group, presence: true

      scope :order_start_or_end_date_asc, -> do
        # mysql returns null values first in opposite to postgres which
        # returns them last by default
        nulls_first = ::Gitlab::Database.postgresql? ? 'NULLS FIRST' : ''
        reorder("COALESCE(start_date, end_date) ASC #{nulls_first}")
      end
    end

    module ClassMethods
      # We support internal references (&epic_id) and cross-references (group.full_path&epic_id)
      #
      # Escaped versions with `&amp;` will be extracted too
      #
      # The parent of epic is group instead of project and therefore we have to define new patterns
      def reference_pattern
        @reference_pattern ||= begin
          combined_prefix = Regexp.union(Regexp.escape(reference_prefix), Regexp.escape(reference_prefix_escaped))
          group_regexp = %r{
            (?<!\w)
            (?<group>#{::Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
          }x
          %r{
            (#{group_regexp})?
            (?:#{combined_prefix})(?<epic>\d+)
          }x
        end
      end

      def link_reference_pattern
        %r{
          (?<url>
            #{Regexp.escape(::Gitlab.config.gitlab.url)}
            \/groups\/(?<group>#{::Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
            \/-\/epics
            \/(?<epic>\d+)
            (?<path>
              (\/[a-z0-9_=-]+)*
            )?
            (?<query>
              \?[a-z0-9_=-]+
              (&[a-z0-9_=-]+)*
            )?
            (?<anchor>\#[a-z0-9_-]+)?
          )
        }x
      end

      def order_by(method)
        if method.to_s == 'start_or_end_date'
          order_start_or_end_date_asc
        else
          super
        end
      end

      def parent_class
        ::Group
      end
    end

    def assignees
      Array(assignee)
    end

    def project
      nil
    end

    def supports_weight?
      false
    end

    def to_reference(from = nil, full: false)
      reference = "#{self.class.reference_prefix}#{iid}"

      return reference unless cross_reference?(from) || full

      "#{group.full_path}#{reference}"
    end

    def cross_reference?(from)
      from && from != group
    end

    # we don't support project epics for epics yet, planned in the future #4019
    def update_project_counter_caches
    end

    def issues(current_user)
      related_issues = ::Issue.select('issues.*, epic_issues.id as epic_issue_id, epic_issues.relative_position')
        .joins(:epic_issue)
        .where("epic_issues.epic_id = #{id}")
        .order('epic_issues.relative_position, epic_issues.id')

      Ability.issues_readable_by_user(related_issues, current_user)
    end

    def mentionable_params
      { group: group, label_url_method: :group_epics_url }
    end

    def discussions_rendered_on_frontend?
      true
    end

    def banzai_render_context(field)
      super.merge(label_url_method: :group_epics_url)
    end
  end
end
