namespace :gitlab do
  namespace :import_export do
    desc "GitLab | Show Import/Export version"
    task version: :environment do
      puts "Import/Export v#{Gitlab::ImportExport.version}"
    end

    desc "GitLab | Display exported DB structure"
    task data: :environment do
      puts YAML.load_file(Gitlab::ImportExport.config_file)['project_tree'].to_yaml(SortKeys: true)
    end

    desc 'GitLab | Bumps the Import/Export version for test_project_export.tar.gz'
    task bump_test_version: :environment do
      Dir.mktmpdir do |tmp_dir|
        system("tar -zxf spec/features/projects/import_export/test_project_export.tar.gz -C #{tmp_dir} > /dev/null")
        File.write(File.join(tmp_dir, 'VERSION'), Gitlab::ImportExport.version, mode: 'w')
        system("tar -zcvf spec/features/projects/import_export/test_project_export.tar.gz -C #{tmp_dir} . > /dev/null")
      end

      puts "Updated to #{Gitlab::ImportExport.version}"
    end
  end
end
