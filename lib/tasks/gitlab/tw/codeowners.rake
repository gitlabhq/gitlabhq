# frozen_string_literal: true

# For information on how to update TW codeowners, see: https://docs.gitlab.com/development/documentation/metadata/#update-the-codeowners-file

module TwCodeowners
  CodeOwnerRule = Struct.new(:category, :writer)
  DocumentOwnerMapping = Struct.new(:path, :writer) do
    def writer_owns_directory?(mappings)
      dir_mappings = mappings.select { |mapping| mapping.directory == directory }

      dir_mappings.count { |mapping| mapping.writer == writer } / dir_mappings.length.to_f > 0.5
    end

    def directory
      @directory ||= "#{File.dirname(path)}/"
    end
  end

  # For groups without an assigned TW, comment out the line.
  CODE_OWNER_RULES = [
    # CodeOwnerRule.new('Activation', ''),
    # CodeOwnerRule.new('Acquisition', ''),
    CodeOwnerRule.new('Agent Foundations', '@sselhorn'),
    CodeOwnerRule.new('AI Framework', '@sselhorn'),
    # CodeOwnerRule.new('Analytics Instrumentation', ''),
    CodeOwnerRule.new('Authentication', '@idurham'),
    CodeOwnerRule.new('Authorization', '@idurham'),
    CodeOwnerRule.new('Build', '@axil @eread'),
    CodeOwnerRule.new('Cells Infrastructure', '@emily.sahlani'),
    CodeOwnerRule.new('Code Creation', '@sselhorn'),
    CodeOwnerRule.new('Code Review', '@brendan777'),
    # CodeOwnerRule.new('Compliance', ''),
    CodeOwnerRule.new('Composition Analysis', '@rdickenson'),
    CodeOwnerRule.new('Container Registry', '@z_painter'),
    CodeOwnerRule.new('Contributor Experience', '@eread'),
    CodeOwnerRule.new('Custom Models', '@fneill'),
    # CodeOwnerRule.new('Database Frameworks', ''),
    # CodeOwnerRule.new('Database Operations', ''),
    # CodeOwnerRule.new('DataOps', ''),
    # CodeOwnerRule.new('Delivery', ''),
    CodeOwnerRule.new('Durability', '@axil'),
    CodeOwnerRule.new('Duo Chat', '@jglassman1'),
    CodeOwnerRule.new('Dynamic Analysis', '@phillipwells'),
    CodeOwnerRule.new('Editor Extensions', '@sselhorn'),
    CodeOwnerRule.new('Engagement', '@kpaizee'),
    CodeOwnerRule.new('Environment Automation', '@lyspin'),
    # CodeOwnerRule.new('Environments', ''),
    # CodeOwnerRule.new('Fulfillment Platform', ''),
    CodeOwnerRule.new('Fuzz Testing', '@rdickenson'),
    CodeOwnerRule.new('Geo', '@axil'),
    CodeOwnerRule.new('Gitaly', '@eread'),
    CodeOwnerRule.new('Global Search', '@ashrafkhamis'),
    # CodeOwnerRule.new('Remote Development', ''),
    CodeOwnerRule.new('Import', '@ashrafkhamis'),
    CodeOwnerRule.new('Knowledge', '@brendan777'),
    # CodeOwnerRule.new('MLOps', ''),
    # CodeOwnerRule.new('Mobile Devops', ''),
    CodeOwnerRule.new('Optimize', '@lciutacu'),
    CodeOwnerRule.new('Organizations', '@z_painter'),
    CodeOwnerRule.new('Organization', '@lciutacu'),
    CodeOwnerRule.new('Package Registry', '@z_painter'),
    CodeOwnerRule.new('Pipeline Authoring', '@marcel.amirault'),
    CodeOwnerRule.new('Pipeline Execution', '@lyspin'),
    CodeOwnerRule.new('Pipeline Security', '@marcel.amirault'),
    # CodeOwnerRule.new('Platform Insights', ''),
    CodeOwnerRule.new('Product Planning', '@msedlakjakubowski'),
    CodeOwnerRule.new('Project Management', '@msedlakjakubowski'),
    CodeOwnerRule.new('Provision', '@lciutacu'),
    CodeOwnerRule.new('Redirect', 'Redirect'),
    # CodeOwnerRule.new('Respond', ''),
    CodeOwnerRule.new('Runner Core', '@rsarangadharan'),
    CodeOwnerRule.new('CI Functions Platform', '@rsarangadharan'),
    # CodeOwnerRule.new('CI Platform', ''),
    CodeOwnerRule.new('Runners Platform', '@rsarangadharan'),
    CodeOwnerRule.new('Seat Management', '@lciutacu'),
    # CodeOwnerRule.new('Security Infrastructure', ''),
    CodeOwnerRule.new('Security Platform Management', '@rlehmann1'),
    CodeOwnerRule.new('Security Policies', '@rlehmann1'),
    CodeOwnerRule.new('Secret Detection', '@phillipwells'),
    CodeOwnerRule.new('Security Insights', '@rlehmann1'),
    CodeOwnerRule.new('Operate', '@axil @eread'),
    CodeOwnerRule.new('Solutions Architecture', '@jfullam @Darwinjs @sbrightwell'),
    CodeOwnerRule.new('Source Code', '@brendan777'),
    CodeOwnerRule.new('Static Analysis', '@rdickenson'),
    CodeOwnerRule.new('Subscription Management', '@lciutacu'),
    CodeOwnerRule.new('Switchboard', '@lyspin'),
    CodeOwnerRule.new('Testing', '@eread'),
    CodeOwnerRule.new('Tutorials', '@gl-docsteam'),
    CodeOwnerRule.new('US Public Sector Services', '@lyspin'),
    CodeOwnerRule.new('Utilization', '@lciutacu')
    # CodeOwnerRule.new('Vulnerability Research', '')
  ].freeze

  CONTRIBUTOR_DOCS_PATH = '/doc/development/'

  CONTRIBUTOR_DOCS_CODE_OWNER_RULES = [
    CodeOwnerRule.new('AI Framework', '@gitlab-org/ai-powered'),
    CodeOwnerRule.new('Analytics Instrumentation',
      '@gitlab-org/analytics-section/product-analytics/engineers/frontend ' \
        '@gitlab-org/analytics-section/analytics-instrumentation/engineers'),
    CodeOwnerRule.new('Authentication', '@gitlab-org/software-supply-chain-security/authentication/approvers'),
    CodeOwnerRule.new('Authorization', '@gitlab-org/software-supply-chain-security/authorization/approvers'),
    CodeOwnerRule.new('Build', '@gitlab-org/distribution'),
    CodeOwnerRule.new('Cells Infrastructure', '@OmarQunsulGitlab @bmarjanovic'),
    CodeOwnerRule.new('Compliance',
      '@gitlab-org/govern/security-policies-frontend @gitlab-org/govern/threat-insights-frontend-team ' \
        '@gitlab-org/govern/threat-insights-backend-team'),
    CodeOwnerRule.new('Composition Analysis',
      '@gitlab-org/secure/composition-analysis-be @gitlab-org/secure/static-analysis'),
    CodeOwnerRule.new('Documentation Guidelines', '@fneill @kpaizee'),
    CodeOwnerRule.new('Duo Workflow', '@gitlab-org/ai-powered'),
    CodeOwnerRule.new('Engineering Productivity', '@gl-dx/pipeline-maintainers'),
    CodeOwnerRule.new('Engagement', '@gitlab-org/growth'),
    CodeOwnerRule.new('Gitaly', '@proglottis @toon'),
    CodeOwnerRule.new('Global Search', '@gitlab-org/search-team/migration-maintainers'),
    CodeOwnerRule.new('Remote Development',
      '@gitlab-org/maintainers/remote-development/backend @gitlab-org/maintainers/remote-development/frontend'),
    CodeOwnerRule.new('Pipeline Authoring', '@gitlab-org/maintainers/cicd-verify'),
    CodeOwnerRule.new('Pipeline Execution', '@gitlab-org/maintainers/cicd-verify'),
    CodeOwnerRule.new('Platform Insights', '@gitlab-org/analytics-section/product-analytics/engineers/frontend'),
    CodeOwnerRule.new('Organizations', '@abdwdd @alexpooley'),
    CodeOwnerRule.new('Operate', '@gitlab-org/distribution'),
    CodeOwnerRule.new('Threat Insights', '@gitlab-org/govern/threat-insights-frontend-team')
  ].freeze

  ERRORS_EXCLUDED_FILES = [
    '/doc/architecture'
  ].freeze

  CODEOWNERS_BLOCK_BEGIN = "# Begin rake-managed-docs-block"
  CODEOWNERS_BLOCK_END = "# End rake-managed-docs-block"

  Document = Struct.new(:group, :redirect) do
    def has_a_valid_group?
      group && !redirect
    end

    def missing_metadata?
      !group && !redirect
    end
  end

  def self.writer_for_group(category, path)
    rules = path.start_with?(CONTRIBUTOR_DOCS_PATH) ? CONTRIBUTOR_DOCS_CODE_OWNER_RULES : CODE_OWNER_RULES
    writer = rules.find { |rule| rule.category == category }&.writer

    if writer.is_a?(String) || writer.nil?
      writer
    else
      writer.call(path)
    end
  end
end

namespace :tw do
  desc 'Generates a list of codeowners for documentation pages.'
  task :codeowners do
    require 'yaml'

    errors = []
    mappings = []

    path = Rails.root.join("doc/**/*.md")
    Dir.glob(path) do |file|
      yaml_data = YAML.load_file(file)
      document = TwCodeowners::Document.new(yaml_data['group'], yaml_data['redirect_to'])
      relative_file = file.delete_prefix(Dir.pwd)

      if document.missing_metadata?
        errors << relative_file unless TwCodeowners::ERRORS_EXCLUDED_FILES.any? do |element|
          relative_file.starts_with?(element)
        end

        next
      end

      writer = TwCodeowners.writer_for_group(document.group, relative_file)
      next unless writer

      mappings << TwCodeowners::DocumentOwnerMapping.new(relative_file, writer) if document.has_a_valid_group?
    end

    transformed_mappings = mappings.map do |mapping|
      if mapping.writer_owns_directory?(mappings)
        TwCodeowners::DocumentOwnerMapping.new(mapping.directory, mapping.writer)
      else
        TwCodeowners::DocumentOwnerMapping.new(mapping.path, mapping.writer)
      end
    end

    deduplicated_mappings = Set.new

    transformed_mappings
      .reject { |mapping| transformed_mappings.any? { |m| m.path == mapping.directory && m.writer == mapping.writer } }
      .each { |mapping| deduplicated_mappings.add("#{mapping.path} #{mapping.writer}") }

    new_docs_owners = deduplicated_mappings.sort.join("\n")

    codeowners_path = Rails.root.join('.gitlab/CODEOWNERS')
    current_codeowners_content = File.read(codeowners_path)

    docs_replace_regex = Regexp.new(
      "#{TwCodeowners::CODEOWNERS_BLOCK_BEGIN}\n[\\s\\S]*?\n#{TwCodeowners::CODEOWNERS_BLOCK_END}"
    )

    new_codeowners_content = current_codeowners_content.gsub(
      docs_replace_regex,
      "#{TwCodeowners::CODEOWNERS_BLOCK_BEGIN}\n#{new_docs_owners}\n#{TwCodeowners::CODEOWNERS_BLOCK_END}"
    )

    File.write(codeowners_path, new_codeowners_content)

    if current_codeowners_content == new_codeowners_content
      puts Rainbow("~ CODEOWNERS already up to date").yellow
    else
      puts Rainbow("✓ CODEOWNERS updated").green
    end

    if errors.present?
      puts ""
      puts Rainbow("✘ Files with missing metadata found:").red
      errors.map { |file| puts file }
    end
  end
end
