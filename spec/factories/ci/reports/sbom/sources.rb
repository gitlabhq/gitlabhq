# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_sbom_source, class: '::Gitlab::Ci::Reports::Sbom::Source' do
    dependency_scanning

    trait :dependency_scanning do
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
    end

    trait :container_scanning do
      type { :container_scanning }

      transient do
        image_name { 'photon' }
        sequence(:image_tag) { |n| "5.#{n}-12345678" }
        operating_system_name { 'Photon OS' }
        sequence(:operating_system_version) { |n| "5.#{n}" }
      end

      data do
        {
          'category' => 'development',
          'image' => {
            'name' => image_name,
            'tag' => image_tag
          },
          'operating_system' => {
            'name' => operating_system_name,
            'version' => operating_system_version
          }
        }
      end
    end

    trait :container_scanning_for_registry do
      type { :container_scanning_for_registry }

      transient do
        image_name { 'photon' }
        sequence(:image_tag) { |n| "5.#{n}-12345678" }
        operating_system_name { 'Photon OS' }
        sequence(:operating_system_version) { |n| "5.#{n}" }
      end

      data do
        {
          'category' => 'development',
          'image' => {
            'name' => image_name,
            'tag' => image_tag
          },
          'operating_system' => {
            'name' => operating_system_name,
            'version' => operating_system_version
          }
        }
      end
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
