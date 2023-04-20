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
      # CodeOwnerRule.new('AI Assisted', ''),
      CodeOwnerRule.new('Analytics Instrumentation', '@lciutacu'),
      CodeOwnerRule.new('Anti-Abuse', '@phillipwells'),
      CodeOwnerRule.new('Application Performance', '@jglassman1'),
      CodeOwnerRule.new('Authentication and Authorization', '@jglassman1'),
      # CodeOwnerRule.new('Billing and Subscription Management', ''),
      CodeOwnerRule.new('Code Review', '@aqualls'),
      CodeOwnerRule.new('Compliance', '@eread'),
      CodeOwnerRule.new('Composition Analysis', '@rdickenson'),
      CodeOwnerRule.new('Environments', '@phillipwells'),
      CodeOwnerRule.new('Container Registry', '@marcel.amirault'),
      CodeOwnerRule.new('Contributor Experience', '@eread'),
      CodeOwnerRule.new('Database', '@aqualls'),
      # CodeOwnerRule.new('DataOps', ''),
      # CodeOwnerRule.new('Delivery', ''),
      CodeOwnerRule.new('Development', '@sselhorn'),
      CodeOwnerRule.new('Distribution', '@axil'),
      CodeOwnerRule.new('Distribution (Charts)', '@axil'),
      CodeOwnerRule.new('Distribution (Omnibus)', '@axil'),
      CodeOwnerRule.new('Documentation Guidelines', '@sselhorn'),
      CodeOwnerRule.new('Dynamic Analysis', '@rdickenson'),
      CodeOwnerRule.new('IDE', '@ashrafkhamis'),
      CodeOwnerRule.new('Foundations', '@sselhorn'),
      # CodeOwnerRule.new('Fulfillment Platform', ''),
      CodeOwnerRule.new('Fuzz Testing', '@rdickenson'),
      CodeOwnerRule.new('Geo', '@axil'),
      CodeOwnerRule.new('Gitaly', '@eread'),
      CodeOwnerRule.new('GitLab Dedicated', '@drcatherinepope'),
      CodeOwnerRule.new('Global Search', '@ashrafkhamis'),
      CodeOwnerRule.new('Import', '@eread'),
      CodeOwnerRule.new('Infrastructure', '@sselhorn'),
      CodeOwnerRule.new('Integrations', '@ashrafkhamis'),
      # CodeOwnerRule.new('Knowledge', ''),
      # CodeOwnerRule.new('MLOps', '')
      CodeOwnerRule.new('Observability', '@drcatherinepope'),
      CodeOwnerRule.new('Optimize', '@lciutacu'),
      CodeOwnerRule.new('Organization', '@lciutacu'),
      CodeOwnerRule.new('Package Registry', '@marcel.amirault'),
      CodeOwnerRule.new('Pipeline Authoring', '@marcel.amirault'),
      CodeOwnerRule.new('Pipeline Execution', '@drcatherinepope'),
      CodeOwnerRule.new('Pipeline Security', '@marcel.amirault'),
      CodeOwnerRule.new('Product Analytics', '@lciutacu'),
      CodeOwnerRule.new('Product Planning', '@msedlakjakubowski'),
      CodeOwnerRule.new('Project Management', '@msedlakjakubowski'),
      CodeOwnerRule.new('Provision', '@fneill'),
      CodeOwnerRule.new('Purchase', '@fneill'),
      CodeOwnerRule.new('Redirect', 'Redirect'),
      CodeOwnerRule.new('Respond', '@msedlakjakubowski'),
      CodeOwnerRule.new('Runner', '@fneill'),
      CodeOwnerRule.new('Runner SaaS', '@fneill'),
      CodeOwnerRule.new('Security Policies', '@rdickenson'),
      CodeOwnerRule.new('Source Code', '@aqualls'),
      CodeOwnerRule.new('Static Analysis', '@rdickenson'),
      CodeOwnerRule.new('Style Guide', '@sselhorn'),
      CodeOwnerRule.new('Tenant Scale', '@lciutacu'),
      CodeOwnerRule.new('Testing', '@eread'),
      CodeOwnerRule.new('Threat Insights', '@rdickenson'),
      CodeOwnerRule.new('Tutorials', '@kpaizee'),
      # CodeOwnerRule.new('US Public Sector Services', ''),
      CodeOwnerRule.new('Utilization', '@fneill')
      # CodeOwnerRule.new('Vulnerability Research', '')
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

    def self.writer_for_group(category)
      CODE_OWNER_RULES.find { |rule| rule.category == category }&.writer
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

      writer = writer_for_group(document.group)
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
