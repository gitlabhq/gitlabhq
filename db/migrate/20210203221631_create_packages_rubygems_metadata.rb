# frozen_string_literal: true

class CreatePackagesRubygemsMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table_with_constraints :packages_rubygems_metadata, id: false do |t|
      t.timestamps_with_timezone
      t.references :package, primary_key: true, index: false, default: nil, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.text :authors
      t.text :files
      t.text :summary

      t.text :description
      t.text :email
      t.text :homepage
      t.text :licenses
      t.text :metadata

      t.text :author
      t.text :bindir
      t.text :cert_chain
      t.text :executables
      t.text :extensions
      t.text :extra_rdoc_files
      t.text :platform
      t.text :post_install_message
      t.text :rdoc_options
      t.text :require_paths
      t.text :required_ruby_version
      t.text :required_rubygems_version
      t.text :requirements
      t.text :rubygems_version
      t.text :signing_key

      t.text_limit :authors, 255
      t.text_limit :files, 255
      t.text_limit :summary, 1024

      t.text_limit :description, 1024
      t.text_limit :email, 255
      t.text_limit :homepage, 255
      t.text_limit :licenses, 255
      t.text_limit :metadata, 255

      t.text_limit :author, 255
      t.text_limit :bindir, 255
      t.text_limit :cert_chain, 255
      t.text_limit :executables, 255
      t.text_limit :extensions, 255
      t.text_limit :extra_rdoc_files, 255
      t.text_limit :platform, 255
      t.text_limit :post_install_message, 255
      t.text_limit :rdoc_options, 255
      t.text_limit :require_paths, 255
      t.text_limit :required_ruby_version, 255
      t.text_limit :required_rubygems_version, 255
      t.text_limit :requirements, 255
      t.text_limit :rubygems_version, 255
      t.text_limit :signing_key, 255
    end
  end

  def down
    drop_table :packages_rubygems_metadata
  end
end
