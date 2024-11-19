# frozen_string_literal: true

module Packages
  module Debian
    module ComponentFile
      extend ActiveSupport::Concern

      included do
        include Sortable
        include FileStoreMounter

        def self.container_foreign_key
          "#{container_type}_id".to_sym
        end

        def self.distribution_class
          "::Packages::Debian::#{container_type.capitalize}Distribution".constantize
        end

        belongs_to :component, class_name: "Packages::Debian::#{container_type.capitalize}Component", inverse_of: :files
        belongs_to :architecture, class_name: "Packages::Debian::#{container_type.capitalize}Architecture", inverse_of: :files, optional: true

        delegate container_type, to: :component

        enum file_type: { packages: 1, sources: 2, di_packages: 3 }
        enum compression_type: { gz: 1, bz2: 2, xz: 3 }

        validates :component, presence: true
        validates :file_type, presence: true
        validates :architecture, presence: true, unless: :sources?
        validates :architecture, absence: true, if: :sources?
        validates :file, length: { minimum: 0, allow_nil: false }
        validates :size, presence: true
        validates :file_store, presence: true
        validates :file_sha256, presence: true

        scope :with_container, ->(container) do
          joins(component: :distribution)
            .where("packages_debian_#{container_type}_distributions" => { container_foreign_key => container.id })
        end

        scope :with_codename_or_suite, ->(codename_or_suite) do
          joins(component: :distribution)
            .merge(distribution_class.with_codename_or_suite(codename_or_suite))
        end

        scope :with_component_name, ->(component_name) do
          joins(:component)
            .where("packages_debian_#{container_type}_components" => { name: component_name })
        end

        scope :with_file_type, ->(file_type) { where(file_type: file_type) }

        scope :with_architecture, ->(architecture) { where(architecture: architecture) }

        scope :with_architecture_name, ->(architecture_name) do
          left_outer_joins(:architecture)
            .where("packages_debian_#{container_type}_architectures" => { name: architecture_name })
        end

        scope :with_compression_type, ->(compression_type) { where(compression_type: compression_type) }
        scope :with_file_sha256, ->(file_sha256) { where(file_sha256: file_sha256) }

        scope :preload_distribution, -> { includes(component: :distribution) }

        scope :updated_before, ->(reference) { where("#{table_name}.updated_at < ?", reference) }

        mount_file_store_uploader Packages::Debian::ComponentFileUploader

        before_validation :update_size_from_file

        def file_name
          case file_type
          when 'di_packages'
            'Packages'
          else
            file_type.capitalize
          end
        end

        def relative_path
          case file_type
          when 'packages'
            "#{component.name}/binary-#{architecture.name}/#{file_name}#{extension}"
          when 'sources'
            "#{component.name}/source/#{file_name}#{extension}"
          when 'di_packages'
            "#{component.name}/debian-installer/binary-#{architecture.name}/#{file_name}#{extension}"
          end
        end

        def empty?
          size == 0
        end

        private

        def extension
          return '' unless compression_type

          ".#{compression_type}"
        end

        def update_size_from_file
          self.size ||= file.size
        end
      end
    end
  end
end
