# frozen_string_literal: true

require 'yaml'

namespace :tw do
  desc 'Generates a list of codeowners for documentation pages.'
  task :codeowners do
    CodeOwnerRule = Struct.new(:category, :writer)

    CODE_OWNER_RULES = [
      CodeOwnerRule.new('Activation', '@kpaizee'),
      CodeOwnerRule.new("Adoption", '@kpaizee'),
      CodeOwnerRule.new('Activation', '@kpaizee'),
      CodeOwnerRule.new('Adoption', '@kpaizee'),
      CodeOwnerRule.new('APM', '@ngaskill'),
      CodeOwnerRule.new('Authentication & Authorization', '@eread'),
      CodeOwnerRule.new('Certify', '@msedlakjakubowski'),
      CodeOwnerRule.new('Code Review', '@aqualls'),
      CodeOwnerRule.new('Compliance', '@eread'),
      CodeOwnerRule.new('Composition Analysis', '@rdickenson'),
      CodeOwnerRule.new('Configure', '@marcia'),
      CodeOwnerRule.new('Container Security', '@ngaskill'),
      CodeOwnerRule.new('Contributor Experience', '@eread'),
      CodeOwnerRule.new('Conversion', '@kpaizee'),
      CodeOwnerRule.new('Database', '@marcia'),
      CodeOwnerRule.new('Development', '@marcia'),
      CodeOwnerRule.new('Distribution', '@axil'),
      CodeOwnerRule.new('Distribution (Charts)', '@axil'),
      CodeOwnerRule.new('Distribution (Omnibus)', '@axil'),
      CodeOwnerRule.new('Documentation Guidelines', '@cnorris'),
      CodeOwnerRule.new('Dynamic Analysis', '@rdickenson'),
      CodeOwnerRule.new('Ecosystem', '@kpaizee'),
      CodeOwnerRule.new('Editor', '@aqualls'),
      CodeOwnerRule.new('Expansion', '@kpaizee'),
      CodeOwnerRule.new('Foundations', '@rdickenson'),
      CodeOwnerRule.new('Fuzz Testing', '@rdickenson'),
      CodeOwnerRule.new('Geo', '@axil'),
      CodeOwnerRule.new('Gitaly', '@eread'),
      CodeOwnerRule.new('Global Search', '@marcia'),
      CodeOwnerRule.new('Health', '@ngaskill'),
      CodeOwnerRule.new('Import', '@ngaskill'),
      CodeOwnerRule.new('Infrastructure', '@marcia'),
      CodeOwnerRule.new('Integrations', '@kpaizee'),
      CodeOwnerRule.new('Knowledge', '@aqualls'),
      CodeOwnerRule.new('License', '@sselhorn'),
      CodeOwnerRule.new('Memory', '@marcia'),
      CodeOwnerRule.new('Monitor', '@ngaskill'),
      CodeOwnerRule.new('Optimize', '@fneill'),
      CodeOwnerRule.new('Package', '@ngaskill'),
      CodeOwnerRule.new('Pipeline Authoring', '@marcel.amirault'),
      CodeOwnerRule.new('Pipeline Execution', '@marcel.amirault'),
      CodeOwnerRule.new('Portfolio Management', '@msedlakjakubowski'),
      CodeOwnerRule.new('Product Intelligence', '@fneill'),
      CodeOwnerRule.new('Product Planning', '@msedlakjakubowski'),
      CodeOwnerRule.new('Project Management', '@msedlakjakubowski'),
      CodeOwnerRule.new('Provision', '@sselhorn'),
      CodeOwnerRule.new('Purchase', '@sselhorn'),
      CodeOwnerRule.new('Redirect', 'Redirect'),
      CodeOwnerRule.new('Release', '@rdickenson'),
      CodeOwnerRule.new('Runner', '@sselhorn'),
      CodeOwnerRule.new('Sharding', '@marcia'),
      CodeOwnerRule.new('Source Code', '@aqualls'),
      CodeOwnerRule.new('Static Analysis', '@rdickenson'),
      CodeOwnerRule.new('Static Site Editor', '@aqualls'),
      CodeOwnerRule.new('Style Guide', '@sselhorn'),
      CodeOwnerRule.new('Testing', '@eread'),
      CodeOwnerRule.new('Threat Insights', '@fneill'),
      CodeOwnerRule.new('Utilization', '@sselhorn'),
      CodeOwnerRule.new('Vulnerability Research', '@fneill'),
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

      puts "#{file.gsub(Dir.pwd, ".")} #{writer}" if document.has_a_valid_group?
    end

    if errors.present?
      puts "-----"
      puts "ERRORS - the following files are missing the correct metadata:"
      errors.map { |file| puts file.gsub(Dir.pwd, ".")}
    end
  end
end
