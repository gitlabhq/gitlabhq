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
      @default_branch = project.default_branch
      @default_protected_branch = ProtectedBranch.default_branch_for(project) if @default_branch
    end

    def execute(cursor: nil, limit: DEFAULT_LIMIT)
      limit = [limit || DEFAULT_LIMIT, MAX_LIMIT].min
      decoded_cursor = decode_cursor(cursor)
      return paginate_from_start(limit) unless decoded_cursor

      return paginate_after_custom_rule(decoded_cursor, limit) if custom_rule_cursor?(decoded_cursor)

      paginate_after_protected_branch_rule(decoded_cursor, limit)
    end

    private

    attr_reader :project, :custom_rules, :protected_branches, :default_branch, :default_protected_branch

    def paginate_from_start(limit)
      return custom_rules_page(limit) if custom_rules.size > limit

      build_page_from_custom_rules(limit)
    end

    def paginate_after_custom_rule(cursor, limit)
      index = custom_rule_index(cursor['name'])

      # No more custom rules to paginate, transition to protected branches
      return paginate_protected_branches_after_custom_rule(limit) if index.nil? || index >= custom_rules.size - 1

      build_page_from_custom_rules(limit, custom_rules[(index + 1)..])
    end

    def paginate_protected_branches_after_custom_rule(limit)
      query = protected_branches

      query = query.excluding_name(default_branch) if default_protected_branch

      branches = query.limit(limit + 1).to_a

      paginate_protected_branches(branches, limit,
        prioritize_default_branch: default_protected_branch.present?)
    end

    def paginate_after_protected_branch_rule(after_cursor, limit)
      query = protected_branches
      query = query.after_name_and_id(after_cursor['name'], after_cursor['id']) if after_cursor && after_cursor['id']

      prioritize_default_branch = first_page_with_default_branch?(after_cursor)
      query = query.excluding_name(default_branch) if after_cursor && after_cursor['id'] && default_branch

      fetch_limit = prioritize_default_branch ? limit : limit + 1
      branches = query.limit(fetch_limit).to_a

      paginate_protected_branches(branches, limit, prioritize_default_branch: prioritize_default_branch)
    end

    def paginate_protected_branches(branches, limit, prioritize_default_branch: false)
      return Page.new if branches.empty?

      if prioritize_default_branch
        has_next = branches.size > (limit - 1)
        page_branches = branches.first(limit - 1)
        page_branches = prioritise_default_branch(page_branches)
      else
        has_next = branches.size > limit
        page_branches = branches.first(limit)
      end

      create_protected_branch_page(page_branches, has_next)
    end

    def create_protected_branch_page(page_branches, has_next)
      cursor = has_next ? encode_cursor(page_branches.last.name, page_branches.last.id) : nil

      Page.new(
        rules: page_branches.map { |pb| ::Projects::BranchRule.new(project, pb) },
        end_cursor: cursor,
        has_next_page: has_next
      )
    end

    def first_page_with_default_branch?(after_cursor)
      default_protected_branch && !after_cursor
    end

    def prioritise_default_branch(page_branches)
      filtered = page_branches - [default_protected_branch]
      [default_protected_branch] + filtered
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
      return ALL_BRANCHES_IDENTIFIER if rule.is_a?(Projects::AllBranchesRule)

      nil
    end

    def custom_rule_names
      [ALL_BRANCHES_IDENTIFIER]
    end

    def decode_cursor(encoded_cursor)
      return unless encoded_cursor

      decoded_cursor = Base64.strict_decode64(encoded_cursor)

      Gitlab::Json.safe_parse(decoded_cursor)
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
