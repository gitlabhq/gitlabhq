# frozen_string_literal: true

module WorkItems
  class ImportCsvService < Issuable::ImportCsv::BaseService
    include Issues::IssueTypeHelpers
    extend ::Gitlab::Utils::Override

    FeatureNotAvailableError = StandardError.new(
      'This feature is currently behind a feature flag and it is not available.'
    )
    NotAuthorizedError = StandardError.new('You do not have permission to import work items in this project.')

    override :initialize
    def initialize(*args)
      super

      @type_errors = {
        blank: [],
        missing: {},
        disallowed: {}
      }
    end

    def execute
      raise NotAuthorizedError unless Ability.allowed?(user, :import_work_items, project)

      super
    end

    def email_results_to_user
      Notify.import_work_items_csv_email(user.id, project.id, results).deliver_later
    end

    private

    attr_accessor :type_errors

    def create_object(attributes)
      super[:work_item]
    end

    def create_object_class
      ::WorkItems::CreateService
    end

    override :attributes_for
    def attributes_for(row)
      super.merge({ work_item_type: match_work_item_type(csv_work_item_type_symbol(row)) })
    end

    def match_work_item_type(work_item_type)
      available_work_item_types[work_item_type&.downcase]
    end

    # todo: This should be updated once we can determine available work item types based on namespace,
    #       see https://gitlab.com/gitlab-org/gitlab/-/issues/524828
    def available_work_item_types
      WorkItems::Type.all.reject { |wit| wit.base_type == :epic }
        .index_by(&:name).with_indifferent_access.transform_keys(&:strip).transform_keys(&:downcase)
    end
    strong_memoize_attr :available_work_item_types

    def preprocess!
      preprocess_milestones!

      with_csv_lines.each do |row, line_no|
        work_item_type = csv_work_item_type_symbol(row)

        if work_item_type.blank?
          type_errors[:blank] << line_no
        elsif missing?(work_item_type)
          # does this work item exist in the range of work items we support?
          (type_errors[:missing][work_item_type] ||= []) << line_no
        elsif !work_item_type_allowed?(work_item_type)
          (type_errors[:disallowed][work_item_type] ||= []) << line_no
        end
      end

      return if type_errors[:blank].empty? &&
        type_errors[:missing].blank? &&
        type_errors[:disallowed].blank?

      results[:type_errors] = type_errors
      raise PreprocessError
    end

    def csv_work_item_type_symbol(row)
      row_type = row[:type]

      strong_memoize_with(:csv_work_item_type_symbol, row_type) do
        # If the row type wasn't provided at all or is blank, fallback to issue
        row_type.blank? ? 'issue' : row_type.strip.downcase
      end
    end

    def missing?(work_item_type_name)
      !available_work_item_types.key?(work_item_type_name)
    end

    def work_item_type_allowed?(work_item_type)
      strong_memoize_with(:work_item_type_allowed, work_item_type) do
        # .tr is needed for work items with spaces in their names (e.g. Key Result)
        create_issue_type_allowed?(project, work_item_type.tr(' ', '_'))
      end
    end

    def preprocess_milestones!
      # Find if these milestones exist in the project or its group and group ancestors
      provided_titles = with_csv_lines.filter_map { |row| row[:milestone]&.strip }.uniq
      finder_params = {
        project_ids: [project.id],
        title: provided_titles
      }
      finder_params[:group_ids] = project.group.self_and_ancestors.select(:id) if project.group
      @available_milestones = MilestonesFinder.new(finder_params).execute
    end

    def extra_create_service_params
      { perform_spam_check: perform_spam_check? }
    end

    def perform_spam_check?
      !user.can_admin_all_resources?
    end
  end
end

WorkItems::ImportCsvService.prepend_mod
