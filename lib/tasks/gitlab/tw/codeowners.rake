# frozen_string_literal: true

require 'yaml'

namespace :tw do
  desc 'Generates a list of codeowners for documentation pages.'
  task :codeowners do
    CodeOwnerRule = Struct.new(:category, :writer)
    DocumentOwnerMapping = Struct.new(:path, :writer) do
      def writer_owns_all_pages?(mappings)
        mappings
          .select { |mapping| mapping.directory == directory }
          .all? { |mapping| mapping.writer == writer }
      end

      def directory
        @directory ||= File.dirname(path)
      end
    end

    CODE_OWNER_RULES = [
      CodeOwnerRule.new('Activation', '@kpaizee'),
      CodeOwnerRule.new("Adoption", '@kpaizee'),
      CodeOwnerRule.new('Activation', '@kpaizee'),
      CodeOwnerRule.new('Adoption', '@kpaizee'),
      CodeOwnerRule.new('Authentication and Authorization', '@eread'),
      CodeOwnerRule.new('Certify', '@msedlakjakubowski'),
      CodeOwnerRule.new('Code Review', '@aqualls'),
      CodeOwnerRule.new('Compliance', '@eread'),
      CodeOwnerRule.new('Composition Analysis', '@rdickenson'),
      CodeOwnerRule.new('Configure', '@sselhorn'),
      CodeOwnerRule.new('Container Security', '@claytoncornell'),
      CodeOwnerRule.new('Contributor Experience', '@eread'),
      CodeOwnerRule.new('Conversion', '@kpaizee'),
      CodeOwnerRule.new('Database', '@aqualls'),
      CodeOwnerRule.new('Development', '@sselhorn'),
      CodeOwnerRule.new('Distribution', '@axil'),
      CodeOwnerRule.new('Distribution (Charts)', '@axil'),
      CodeOwnerRule.new('Distribution (Omnibus)', '@axil'),
      CodeOwnerRule.new('Documentation Guidelines', '@sselhorn'),
      CodeOwnerRule.new('Dynamic Analysis', '@rdickenson'),
      CodeOwnerRule.new('Ecosystem', '@kpaizee'),
      CodeOwnerRule.new('Editor', '@aqualls'),
      CodeOwnerRule.new('Expansion', '@kpaizee'),
      CodeOwnerRule.new('Foundations', '@rdickenson'),
      CodeOwnerRule.new('Fuzz Testing', '@rdickenson'),
      CodeOwnerRule.new('Geo', '@axil'),
      CodeOwnerRule.new('Gitaly', '@eread'),
      CodeOwnerRule.new('Global Search', '@sselhorn'),
      CodeOwnerRule.new('Import', '@eread'),
      CodeOwnerRule.new('Infrastructure', '@sselhorn'),
      CodeOwnerRule.new('Integrations', '@kpaizee'),
      CodeOwnerRule.new('Knowledge', '@aqualls'),
      CodeOwnerRule.new('Memory', '@sselhorn'),
      CodeOwnerRule.new('Monitor', '@msedlakjakubowski'),
      CodeOwnerRule.new('Observability', 'msedlakjakubowski'),
      CodeOwnerRule.new('Optimize', '@fneill'),
      CodeOwnerRule.new('Package', '@claytoncornell'),
      CodeOwnerRule.new('Pipeline Authoring', '@marcel.amirault'),
      CodeOwnerRule.new('Pipeline Execution', '@marcel.amirault'),
      CodeOwnerRule.new('Pipeline Insights', '@marcel.amirault'),
      CodeOwnerRule.new('Portfolio Management', '@msedlakjakubowski'),
      CodeOwnerRule.new('Product Intelligence', '@claytoncornell'),
      CodeOwnerRule.new('Product Planning', '@msedlakjakubowski'),
      CodeOwnerRule.new('Project Management', '@msedlakjakubowski'),
      CodeOwnerRule.new('Provision', '@fneill'),
      CodeOwnerRule.new('Purchase', '@fneill'),
      CodeOwnerRule.new('Redirect', 'Redirect'),
      CodeOwnerRule.new('Release', '@rdickenson'),
      CodeOwnerRule.new('Respond', '@msedlakjakubowski'),
      CodeOwnerRule.new('Runner', '@sselhorn'),
      CodeOwnerRule.new('Pods', '@sselhorn'),
      CodeOwnerRule.new('Source Code', '@aqualls'),
      CodeOwnerRule.new('Static Analysis', '@rdickenson'),
      CodeOwnerRule.new('Style Guide', '@sselhorn'),
      CodeOwnerRule.new('Testing', '@eread'),
      CodeOwnerRule.new('Threat Insights', '@claytoncornell'),
      CodeOwnerRule.new('Utilization', '@fneill'),
      CodeOwnerRule.new('Vulnerability Research', '@claytoncornell'),
      CodeOwnerRule.new('Workspace', '@fneill')
    ].freeze

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

      if document.missing_metadata?
        errors << file
        next
      end

      writer = writer_for_group(document.group)
      next unless writer

      mappings << DocumentOwnerMapping.new(file.delete_prefix(Dir.pwd), writer) if document.has_a_valid_group?
    end

    deduplicated_mappings = Set.new

    mappings.each do |mapping|
      if mapping.writer_owns_all_pages?(mappings)
        deduplicated_mappings.add("#{mapping.directory}/ #{mapping.writer}")
      else
        deduplicated_mappings.add("#{mapping.path} #{mapping.writer}")
      end
    end

    deduplicated_mappings.each { |mapping| puts mapping }

    if errors.present?
      puts "-----"
      puts "ERRORS - the following files are missing the correct metadata:"
      errors.map { |file| puts file.gsub(Dir.pwd, ".")}
    end
  end
end
