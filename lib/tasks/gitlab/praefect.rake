# frozen_string_literal: true

namespace :gitlab do
  namespace :praefect do
    def int?(string)
      true if Integer(string)
    rescue StandardError
      false
    end

    def print_checksums(header, row)
      header.each_with_index do |val, i|
        width = [val.length, row[i].length].max
        header[i] = header[i].ljust(width)
        row[i] = row[i].ljust(width)
      end

      header_str = header.join(' | ')
      puts header_str
      puts '-' * header_str.length
      puts row.join(' | ')
    end

    desc 'GitLab | Praefect | Check replicas'
    task :replicas, [:project_id] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless int?(args.project_id)
        puts 'argument must be a valid project_id'
        next
      end

      project = Project.find_by_id(args.project_id)
      if project.nil?
        puts 'No project was found with that id'
        next
      end

      begin
        replicas_resp = project.repository.replicas

        sorted_replicas = replicas_resp.replicas.sort_by { |r| r.repository.storage_name }

        header = ['Project name'] << "#{replicas_resp.primary.repository.storage_name} (primary)"
        header.concat(sorted_replicas.map { |r| r.repository.storage_name })

        row = [project.name] << replicas_resp.primary.checksum
        row.concat(sorted_replicas.map { |r| r.checksum })
      rescue StandardError
        puts 'Something went wrong when getting replicas.'
        next
      end

      puts "\n"
      print_checksums(header, row)
    end
  end
end
