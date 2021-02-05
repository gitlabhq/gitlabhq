# frozen_string_literal: true

namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | Show Import/Export version'
    task version: :environment do
      puts "Import/Export v#{Gitlab::ImportExport.version}"
    end

    desc 'GitLab | Import/Export | Display exported DB structure'
    task data: :environment do
      puts Gitlab::ImportExport::Config.new.to_h['project_tree'].to_yaml(SortKeys: true)
    end

    desc 'GitLab | Import/Export | Bumps the Import/Export version in fixtures and project templates'
    task bump_version: :environment do
      archives = Dir['vendor/project_templates/*.tar.gz']
      archives.push('spec/features/projects/import_export/test_project_export.tar.gz')

      archives.each do |archive|
        raise ArgumentError unless File.exist?(archive)

        Dir.mktmpdir do |tmp_dir|
          system("tar -zxf #{archive} -C #{tmp_dir} > /dev/null")
          File.write(File.join(tmp_dir, 'VERSION'), Gitlab::ImportExport.version, mode: 'w')
          system("tar -zcvf #{archive} -C #{tmp_dir} . > /dev/null")
        end
      end

      puts "Updated #{archives} to #{Gitlab::ImportExport.version}."
    end
  end
end
