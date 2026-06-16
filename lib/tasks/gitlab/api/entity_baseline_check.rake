# frozen_string_literal: true

namespace :gitlab do
  namespace :api do
    desc 'GitLab | API | Check for new high-impact entities missing from the EntityExposureGrowth baseline'
    task check_high_impact_entity_baseline: :environment do
      require 'yaml'

      baseline_path = Rails.root.join('rubocop/cop/api/config/api_entity_exposure_baseline.yml')
      baseline = YAML.load_file(baseline_path) || {}

      new_entries = []
      manual_review_entries = []

      Gitlab::RestApi::EntityUsageRadiusAnalyzer.new.high_impact_entities.each do |entity_class, usage_radius|
        path = Gitlab::RestApi::EntityUsageRadiusAnalyzer.entity_file_path(entity_class)
        next unless path
        next if baseline.key?(path)

        fields = Gitlab::RestApi::EntityUsageRadiusAnalyzer.extract_field_names(path).sort
        entry = {
          class_name: entity_class.name,
          path: path,
          usage_radius: usage_radius,
          fields: fields
        }

        # Entities exposing fields dynamically or via macros/EE overrides parse to no
        # fields. Emitting them as `path: []` would inject a misleading allowlist, so we
        # flag them for manual review instead of including them in the copy-paste snippet.
        if fields.empty?
          manual_review_entries << entry
        else
          new_entries << entry
        end
      end

      if new_entries.empty? && manual_review_entries.empty?
        puts 'No new high-impact entities detected. Baseline is up to date.'
        next
      end

      puts '=' * 72
      puts 'NEW HIGH-IMPACT API ENTITIES DETECTED'
      puts '=' * 72
      (new_entries + manual_review_entries).each do |entry|
        puts
        puts "  Entity:       #{entry[:class_name]}"
        puts "  File:         #{entry[:path]}"
        puts "  Usage radius: #{entry[:usage_radius]} endpoints"
        puts "  Exposed:      #{entry[:fields].size} field(s)"
      end

      if new_entries.any?
        puts
        puts '=' * 72
        puts 'Add the following to:'
        puts '  rubocop/cop/api/config/api_entity_exposure_baseline.yml'
        puts '=' * 72
        snippet = new_entries.each_with_object({}) { |entry, hash| hash[entry[:path]] = entry[:fields] }
        puts snippet.to_yaml.delete_prefix("---\n")
      end

      if manual_review_entries.any?
        puts
        puts '=' * 72
        puts 'MANUAL REVIEW REQUIRED: no exposed fields could be extracted'
        puts '=' * 72
        puts 'These entities expose fields dynamically or via macros/EE overrides that'
        puts 'cannot be parsed automatically. Check the elements yourself and add them'
        puts 'to the YAML manually:'
        manual_review_entries.each { |entry| puts "  #{entry[:path]} (#{entry[:class_name]})" }
        puts
      end

      puts 'Documentation: ' \
        'https://docs.gitlab.com/development/api_styleguide/' \
        '#high-impact-entities-and-feature-bounded-entities'

      abort('Baseline drift detected — see listing above.')
    end
  end
end
