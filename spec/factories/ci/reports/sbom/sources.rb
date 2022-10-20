# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_source, class: '::Gitlab::Ci::Reports::Sbom::Source' do
    type { :dependency_scanning }

    transient do
      sequence(:input_file_path) { |n| "subproject-#{n}/package-lock.json" }
      sequence(:source_file_path) { |n| "subproject-#{n}/package.json" }
    end

    data do
      {
        'category' => 'development',
        'input_file' => { 'path' => input_file_path },
        'source_file' => { 'path' => source_file_path },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Sbom::Source.new(
        type: type,
        data: data
      )
    end
  end
end
