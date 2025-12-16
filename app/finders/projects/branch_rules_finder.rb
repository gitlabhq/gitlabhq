# frozen_string_literal: true

module Projects
  class BranchRulesFinder
    DEFAULT_LIMIT = 20
    MAX_LIMIT = 100
    ALL_BRANCHES_IDENTIFIER = 'all_branches'

    Page = Struct.new(:rules, :end_cursor, :has_next_page, keyword_init: true) do
      def initialize(rules: [], end_cursor: nil, has_next_page: false)
        super
      end
    end

    def initialize(project, custom_rules:, protected_branches:)
      @project = project
      @custom_rules = custom_rules
      @protected_branches = protected_branches
    end

    def execute(cursor: nil, limit: DEFAULT_LIMIT)
      limit = [limit || DEFAULT_LIMIT, MAX_LIMIT].min
      decoded_cursor = decode_cursor(cursor)
      return paginate_from_start(limit) unless decoded_cursor

      return paginate_after_custom_rule(decoded_cursor, limit) if custom_rule_cursor?(decoded_cursor)

      paginate_after_protected_branch_rule(decoded_cursor, limit)
    end

    private

    attr_reader :project, :custom_rules, :protected_branches

    def paginate_from_start(limit)
      return custom_rules_page(limit) if custom_rules.size > limit

      build_page_from_custom_rules(limit)
    end

    def paginate_after_custom_rule(cursor, limit)
      index = custom_rule_index(cursor['name'])
      # If there are no more custom rules after the cursor, return protected branches
      return paginate_after_protected_branch_rule(nil, limit) if index.nil? || index >= custom_rules.size - 1

      build_page_from_custom_rules(limit, custom_rules[(index + 1)..])
    end

    def paginate_after_protected_branch_rule(after_cursor, limit)
      query = protected_branches

      # Only apply cursor if we have both name and id
      query = query.after_name_and_id(after_cursor['name'], after_cursor['id']) if after_cursor && after_cursor['id']

      # Add one extra to check if a next page exists
      branches = query.limit(limit + 1).to_a

      return Page.new if branches.empty?

      has_next = branches.size > limit
      page_branches = branches.first(limit)
      cursor = has_next ? encode_cursor(page_branches.last.name, page_branches.last.id) : nil

      Page.new(
        rules: page_branches.map { |pb| ::Projects::BranchRule.new(project, pb) },
        end_cursor: cursor,
        has_next_page: has_next
      )
    end

    def custom_rules_page(limit)
      rules = custom_rules.first(limit)

      Page.new(rules: rules, end_cursor: encode_cursor(identifier_for_rule(rules.last)),
        has_next_page: custom_rules.size > limit)
    end

    def build_page_from_custom_rules(limit, custom_rules_subset = nil)
      custom_rules_subset ||= custom_rules
      remaining_limit = limit - custom_rules_subset.size

      if remaining_limit <= 0
        custom_rules_only_page(custom_rules_subset)
      else
        custom_and_protected_rules_page(custom_rules_subset, remaining_limit)
      end
    end

    def custom_rules_only_page(custom_rules_subset)
      Page.new(
        rules: custom_rules_subset,
        end_cursor: encode_cursor(identifier_for_rule(custom_rules_subset.last)),
        has_next_page: protected_branches.exists?
      )
    end

    def custom_and_protected_rules_page(custom_rules_subset, remaining_limit)
      protected_page = paginate_after_protected_branch_rule(nil, remaining_limit)

      Page.new(
        rules: custom_rules_subset + protected_page.rules,
        end_cursor: protected_page.end_cursor,
        has_next_page: protected_page.has_next_page
      )
    end

    def custom_rule_index(cursor_name)
      custom_rules.index do |rule|
        identifier_for_rule(rule) == cursor_name
      end
    end

    def custom_rule_cursor?(cursor)
      cursor['id'].blank? && custom_rule_names.include?(cursor['name'])
    end

    def identifier_for_rule(rule)
      return unless rule

      ALL_BRANCHES_IDENTIFIER if rule.is_a?(Projects::AllBranchesRule)
    end

    def custom_rule_names
      [ALL_BRANCHES_IDENTIFIER]
    end

    def decode_cursor(encoded_cursor)
      return unless encoded_cursor

      decoded_cursor = Base64.strict_decode64(encoded_cursor)

      Gitlab::Json.parse(decoded_cursor)
    rescue ArgumentError, JSON::ParserError => e
      raise Gitlab::Graphql::Errors::ArgumentError, "Invalid cursor: #{e.message}"
    end

    def encode_cursor(name, id = nil)
      return unless name

      cursor = { name: name, id: id }.to_json
      Base64.strict_encode64(cursor)
    end
  end
end

Projects::BranchRulesFinder.prepend_mod_with('Projects::BranchRulesFinder')
