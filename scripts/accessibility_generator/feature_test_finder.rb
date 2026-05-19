# frozen_string_literal: true

# Finds and scores relevant feature test files for a given E2E journey
class FeatureTestFinder
  GENERIC_WORDS = %w[
    user users views test spec create show edit delete list index new update
    manage performs does has can will should verify check validate
  ].freeze

  MINIMAL_GENERIC_WORDS = %w[user users test spec].freeze

  SEARCH_GLOBS = [
    'spec/features/projects/**/*%<term>s*_spec.rb',
    'spec/features/merge_request/*%<term>s*_spec.rb'
  ].freeze

  # Comprehensive mapping of E2E test directories to feature test directories
  E2E_TO_FEATURE_DOMAIN_MAPPING = {
    # Create stage
    'source_editor' => ['files', 'projects/files'],
    'web_ide' => ['files', 'projects/files'],
    'repository' => ['files', 'tree', 'commits', 'projects/repository'],
    'merge_request' => ['merge_request', 'projects/merge_requests'],
    'snippet' => ['snippets', 'projects/snippets'],
    'wiki' => ['projects/wiki'],

    # Plan stage
    'issue' => ['work_items/issues', 'work_items/list', 'work_items/detail'],
    'issue_boards' => ['boards', 'projects/boards'],
    'milestone' => ['milestones', 'projects/milestones'],
    'design_management' => ['work_items/issues/design_management'],

    # Verify stage
    'pipeline' => ['projects/pipelines', 'pipelines'],
    'job' => ['projects/jobs'],
    'runner' => ['runners'],

    # Package stage
    'package' => ['packages'],
    'container_registry' => ['container_registry'],

    # Secure stage
    'security_dashboard' => ['security'],

    # Deploy stage
    'kubernetes' => ['clusters'],
    'environments' => ['environments']
  }.freeze

  def initialize(gitlab_root, max_results: 10)
    @gitlab_root = gitlab_root
    @max_results = max_results
  end

  def find_related_tests(e2e_tests, config)
    candidates = []

    # Strategy 1: Use manual hints from YAML config if provided
    candidates.concat(search_by_manual_hints(config)) if config['feature_test_hints']

    # Strategy 2: Search by domain paths extracted from E2E test structure
    domain_paths = extract_domain_paths_from_e2e(e2e_tests)
    candidates.concat(search_by_domain_paths(domain_paths))

    # Strategy 3: Search by specific terms (fallback)
    candidates.concat(search_by_specific_terms(e2e_tests, config))

    # Rank, filter, and select top results
    rank_and_filter_candidates(candidates, e2e_tests, config)
  end

  private

  def map_e2e_to_feature_domain(e2e_domain)
    E2E_TO_FEATURE_DOMAIN_MAPPING[e2e_domain] || e2e_domain
  end

  def search_by_manual_hints(config)
    results = []

    config['feature_test_hints'].each do |hint|
      pattern = File.join(@gitlab_root, 'spec', 'features', hint, '*_spec.rb')
      results.concat(Dir.glob(pattern))
    end

    results
  end

  def extract_domain_paths_from_e2e(e2e_tests)
    # Extract domain names from E2E test paths
    # From: qa/qa/specs/features/browser_ui/3_create/source_editor/...
    # Extract: ["source_editor", "repository"]
    e2e_tests.filter_map do |test|
      path_parts = test['path'].split('/')
      # Find the stage directory (e.g., "3_create", "2_plan")
      stage_index = path_parts.index { |p| p =~ /^\d+_\w+$/ }
      # Get the domain directory after the stage
      path_parts[stage_index + 1] if stage_index
    end.uniq
  end

  def search_by_domain_paths(domain_paths)
    results = []

    domain_paths.each do |domain|
      feature_domains = map_e2e_to_feature_domain(domain)

      Array(feature_domains).each do |feature_domain|
        pattern = File.join(@gitlab_root, 'spec', 'features', 'projects', feature_domain, '*_spec.rb')
        results.concat(Dir.glob(pattern))

        # Also search in top-level features for non-project domains
        if feature_domain.include?('/')
          pattern = File.join(@gitlab_root, 'spec', 'features', feature_domain, '*_spec.rb')
          results.concat(Dir.glob(pattern))
        end
      end
    end

    results
  end

  def search_by_specific_terms(e2e_tests, config)
    specific_terms = extract_specific_terms(e2e_tests, config)

    SEARCH_GLOBS.flat_map do |search_glob|
      specific_terms.flat_map do |term|
        Dir.glob(File.join(@gitlab_root, format(search_glob, term: term)))
      end
    end
  end

  def extract_specific_terms(e2e_tests, config)
    terms = []

    e2e_tests.each do |test|
      filename = spec_filename(test['path'])
      words = filename.split('_')
      specific_words = filter_generic_words(words)
      terms.concat(specific_words)
    end

    # Also extract from journey name
    journey_words = config['journey_name'].split('_')
    specific_journey_words = filter_generic_words(journey_words)
    terms.concat(specific_journey_words)

    terms.uniq
  end

  def rank_and_filter_candidates(candidates, e2e_tests, config)
    # Remove duplicates and make paths relative
    candidates = candidates
      .uniq
      .map { |f| f.delete_prefix(@gitlab_root) }

    # Score each candidate by relevance
    scored = candidates.map do |file|
      score = calculate_relevance_score(file, e2e_tests, config)
      [file, score]
    end

    # Sort by score (descending), then alphabetically for ties
    limit = [scored.size, @max_results].min

    scored
      .sort_by { |file, score| [-score, file] }
      .first(limit)
      .map(&:first)
  end

  def calculate_relevance_score(file, e2e_tests, config)
    score = 0

    score += score_by_directory(file)
    score += score_by_hint_match(file, config)
    score += score_by_shared_terminology(file, e2e_tests)
    score += score_by_action_verbs(file)
    score += penalty_for_irrelevant_directories(file)

    score
  end

  def score_by_directory(file)
    return 10 if file.include?('spec/features/projects/')
    return 8 if file.include?('spec/features/work_items/')
    return 5 if file.include?('spec/features/merge_request/')

    0
  end

  def score_by_hint_match(file, config)
    return 0 unless config['feature_test_hints']

    config['feature_test_hints'].sum do |hint|
      file.include?("spec/features/#{hint}/") ? 15 : 0
    end
  end

  def score_by_shared_terminology(file, e2e_tests)
    feature_filename = spec_filename(file)

    e2e_tests.sum do |test|
      e2e_filename = spec_filename(test['path'])
      e2e_words = e2e_filename.split('_')
      feature_words = feature_filename.split('_')

      shared_words = filter_generic_words(e2e_words & feature_words, generic_list: MINIMAL_GENERIC_WORDS)

      shared_words.length * 3
    end
  end

  def score_by_action_verbs(file)
    feature_filename = spec_filename(file, downcase: true)
    primary_actions = %w[create edit delete browse]
    secondary_actions = %w[view show list update upload replace]

    score = 0
    primary_actions.each { |verb| score += 4 if feature_filename.include?(verb) }
    secondary_actions.each { |verb| score += 2 if feature_filename.include?(verb) }
    score
  end

  def penalty_for_irrelevant_directories(file)
    penalty = 0
    penalty -= 20 if file.include?('admin/')
    penalty -= 15 if file.include?('system/')
    penalty -= 10 if file.include?('dashboard/') && file.exclude?('security_dashboard')
    penalty
  end

  # Helper methods
  def spec_filename(path, downcase: false)
    name = File.basename(path, '_spec.rb')
    downcase ? name.downcase : name
  end

  def filter_generic_words(words, generic_list: GENERIC_WORDS, min_length: 3)
    words.reject { |word| generic_list.include?(word) || word.length <= min_length }
  end
end
