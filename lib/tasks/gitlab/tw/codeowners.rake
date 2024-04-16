# frozen_string_literal: true

namespace :tw do
  desc 'Generates a list of codeowners for documentation pages.'
  task :codeowners do
    require 'yaml'

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

    CODE_OWNER_RULES = [
      # CodeOwnerRule.new('Activation', ''),
      # CodeOwnerRule.new('Acquisition', ''),
      CodeOwnerRule.new('AI Framework', '@sselhorn'),
      CodeOwnerRule.new('AI Model Validation', '@sselhorn'),
      # CodeOwnerRule.new('Analytics Instrumentation', ''),
      CodeOwnerRule.new('Anti-Abuse', '@phillipwells'),
      CodeOwnerRule.new('Authentication', '@jglassman1'),
      CodeOwnerRule.new('Authorization', '@jglassman1'),
      # CodeOwnerRule.new('Billing and Subscription Management', ''),
      CodeOwnerRule.new('Cloud Connector', '@jglassman1'),
      CodeOwnerRule.new('Code Creation', '@jglassman1'),
      CodeOwnerRule.new('Code Review', '@aqualls'),
      CodeOwnerRule.new('Compliance', '@eread'),
      CodeOwnerRule.new('Composition Analysis', '@rdickenson'),
      CodeOwnerRule.new('Container Registry', '@marcel.amirault'),
      CodeOwnerRule.new('Contributor Experience', '@eread'),
      CodeOwnerRule.new('Custom Models', '@sselhorn'),
      # CodeOwnerRule.new('Database', ''),
      CodeOwnerRule.new('DataOps', '@sselhorn'),
      # CodeOwnerRule.new('Delivery', ''),
      CodeOwnerRule.new('Distribution', '@axil'),
      CodeOwnerRule.new('Distribution (Charts)', '@axil'),
      CodeOwnerRule.new('Distribution (Omnibus)', '@eread'),
      CodeOwnerRule.new('Duo Chat', '@sselhorn'),
      CodeOwnerRule.new('Dynamic Analysis', '@rdickenson'),
      CodeOwnerRule.new('Editor Extensions', '@aqualls'),
      CodeOwnerRule.new('Environments', '@phillipwells'),
      CodeOwnerRule.new('Foundations', '@sselhorn'),
      # CodeOwnerRule.new('Fulfillment Platform', ''),
      CodeOwnerRule.new('Fuzz Testing', '@rdickenson'),
      CodeOwnerRule.new('Geo', '@axil'),
      CodeOwnerRule.new('Gitaly', '@eread'),
      CodeOwnerRule.new('GitLab Dedicated', '@lyspin'),
      CodeOwnerRule.new('Global Search', '@ashrafkhamis'),
      CodeOwnerRule.new('IDE', '@ashrafkhamis'),
      CodeOwnerRule.new('Import and Integrate', '@eread @ashrafkhamis'),
      CodeOwnerRule.new('Infrastructure', '@sselhorn'),
      # CodeOwnerRule.new('Knowledge', ''),
      CodeOwnerRule.new('MLOps', '@sselhorn'),
      # CodeOwnerRule.new('Observability', ''),
      CodeOwnerRule.new('Optimize', '@lciutacu'),
      CodeOwnerRule.new('Organization', '@lciutacu'),
      CodeOwnerRule.new('Package Registry', '@phillipwells'),
      CodeOwnerRule.new('Pipeline Authoring', '@marcel.amirault @lyspin'),
      CodeOwnerRule.new('Pipeline Execution', '@marcel.amirault @lyspin'),
      CodeOwnerRule.new('Pipeline Security', '@marcel.amirault'),
      CodeOwnerRule.new('Product Analytics', '@lciutacu'),
      CodeOwnerRule.new('Product Planning', '@msedlakjakubowski'),
      CodeOwnerRule.new('Project Management', '@msedlakjakubowski'),
      CodeOwnerRule.new('Provision', '@fneill'),
      CodeOwnerRule.new('Redirect', 'Redirect'),
      # CodeOwnerRule.new('Respond', ''),
      CodeOwnerRule.new('Runner', '@fneill'),
      CodeOwnerRule.new('Hosted Runners', '@fneill'),
      CodeOwnerRule.new('Security Policies', '@rdickenson'),
      CodeOwnerRule.new('Solutions Architecture', '@jfullam @brianwald @Darwinjs'),
      CodeOwnerRule.new('Source Code', '@msedlakjakubowski'),
      CodeOwnerRule.new('Static Analysis', '@rdickenson'),
      # CodeOwnerRule.new('Subscription Management', ''),
      CodeOwnerRule.new('Tenant Scale', '@lciutacu'),
      CodeOwnerRule.new('Testing', '@eread'),
      CodeOwnerRule.new('Threat Insights', '@rdickenson'),
      CodeOwnerRule.new('Tutorials', '@kpaizee'),
      # CodeOwnerRule.new('US Public Sector Services', ''),
      CodeOwnerRule.new('Utilization', '@fneill')
      # CodeOwnerRule.new('Vulnerability Research', '')
    ].freeze

    CONTRIBUTOR_DOCS_PATH = '/doc/development/'
    CONTRIBUTOR_DOCS_CODE_OWNER_RULES = [
      CodeOwnerRule.new('Analytics Instrumentation',
        '@gitlab-org/analytics-section/product-analytics/engineers/frontend ' \
        '@gitlab-org/analytics-section/analytics-instrumentation/engineers'),
      CodeOwnerRule.new('Authentication', '@gitlab-org/govern/authentication/approvers'),
      CodeOwnerRule.new('Authorization', '@gitlab-org/govern/authorization/approvers'),
      CodeOwnerRule.new('Compliance',
        '@gitlab-org/govern/security-policies-frontend @gitlab-org/govern/threat-insights-frontend-team ' \
        '@gitlab-org/govern/threat-insights-backend-team'),
      CodeOwnerRule.new('Composition Analysis',
        '@gitlab-org/secure/composition-analysis-be @gitlab-org/secure/static-analysis'),
      CodeOwnerRule.new('Distribution', '@gitlab-org/distribution'),
      CodeOwnerRule.new('Documentation Guidelines', '@sselhorn'),
      CodeOwnerRule.new('Engineering Productivity', '@gl-quality/eng-prod'),
      CodeOwnerRule.new('Foundations', '@gitlab-org/manage/foundations/engineering'),
      CodeOwnerRule.new('Gitaly', '@proglottis @toon'),
      CodeOwnerRule.new('Global Search', '@gitlab-org/search-team/migration-maintainers'),
      CodeOwnerRule.new('IDE',
        '@gitlab-org/maintainers/remote-development/backend @gitlab-org/maintainers/remote-development/frontend'),
      CodeOwnerRule.new('Pipeline Authoring', '@gitlab-org/maintainers/cicd-verify'),
      CodeOwnerRule.new('Pipeline Execution', '@gitlab-org/maintainers/cicd-verify'),
      CodeOwnerRule.new('Product Analytics', '@gitlab-org/analytics-section/product-analytics/engineers/frontend'),
      CodeOwnerRule.new('Tenant Scale', '@abdwdd @alexpooley @manojmj'),
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

    errors = []
    mappings = []

    path = Rails.root.join("doc/**/*.md")
    Dir.glob(path) do |file|
      yaml_data = YAML.load_file(file)
      document = Document.new(yaml_data['group'], yaml_data['redirect_to'])
      relative_file = file.delete_prefix(Dir.pwd)

      if document.missing_metadata?
        errors << relative_file unless ERRORS_EXCLUDED_FILES.any? { |element| relative_file.starts_with?(element) }
        next
      end

      writer = writer_for_group(document.group, relative_file)
      next unless writer

      mappings << DocumentOwnerMapping.new(relative_file, writer) if document.has_a_valid_group?
    end

    transformed_mappings = mappings.map do |mapping|
      if mapping.writer_owns_directory?(mappings)
        DocumentOwnerMapping.new(mapping.directory, mapping.writer)
      else
        DocumentOwnerMapping.new(mapping.path, mapping.writer)
      end
    end

    deduplicated_mappings = Set.new

    transformed_mappings
      .reject { |mapping| transformed_mappings.any? { |m| m.path == mapping.directory && m.writer == mapping.writer } }
      .each { |mapping| deduplicated_mappings.add("#{mapping.path} #{mapping.writer}") }

    new_docs_owners = deduplicated_mappings.sort.join("\n")

    codeowners_path = Rails.root.join('.gitlab/CODEOWNERS')
    current_codeowners_content = File.read(codeowners_path)

    docs_replace_regex = Regexp.new("#{CODEOWNERS_BLOCK_BEGIN}\n[\\s\\S]*?\n#{CODEOWNERS_BLOCK_END}")

    new_codeowners_content = current_codeowners_content
        .gsub(docs_replace_regex, "#{CODEOWNERS_BLOCK_BEGIN}\n#{new_docs_owners}\n#{CODEOWNERS_BLOCK_END}")

    File.write(codeowners_path, new_codeowners_content)

    if current_codeowners_content == new_codeowners_content
      puts "~ CODEOWNERS already up to date".color(:yellow)
    else
      puts "✓ CODEOWNERS updated".color(:green)
    end

    if errors.present?
      puts ""
      puts "✘ Files with missing metadata found:".color(:red)
      errors.map { |file| puts file }
    end
  end
end
