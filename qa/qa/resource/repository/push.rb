# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class Push < Base
        attr_accessor :file_name, :file_content, :commit_message,
          :branch_name, :new_branch, :output, :repository_http_uri,
          :repository_ssh_uri, :ssh_key, :user, :use_lfs, :tag_name

        attr_writer :remote_branch, :gpg_key_id, :merge_request_push_options

        def initialize
          @file_name = "file-#{SecureRandom.hex(8)}.txt"
          @file_content = '# This is test file'
          @commit_message = "This is a test commit"
          @new_branch = true
          @repository_http_uri = ""
          @ssh_key = nil
          @use_lfs = false
          @tag_name = nil
          @gpg_key_id = nil
          @merge_request_push_options = nil
        end

        def remote_branch
          @remote_branch ||= branch_name
        end

        def directory=(dir)
          raise "Must set directory as a Pathname" unless dir.is_a?(Pathname)

          @directory = dir
        end

        def files=(files)
          if !files.is_a?(Array) ||
              files.empty? ||
              files.any? { |file| !file.has_key?(:name) || !file.has_key?(:content) }
            raise ArgumentError, "Please provide an array of hashes e.g.: [{name: 'file1', content: 'foo'}]"
          end

          @files = files
        end

        def fabricate!
          Git::Repository.perform do |repository|
            @output = ''

            if ssh_key
              repository.uri = repository_ssh_uri
              repository.use_ssh_key(ssh_key)
            else
              repository.uri = repository_http_uri
              repository.use_default_credentials unless user
            end

            repository.use_lfs = use_lfs

            name = 'GitLab QA'
            email = 'root@gitlab.com'

            if user
              repository.username = user.username
              repository.password = user.password
              name = user.name
              email = user.email
            end

            unless @gpg_key_id.nil?
              repository.gpg_key_id = @gpg_key_id
            end

            @output += repository.clone
            repository.configure_identity(name, email)

            @branch_name ||= default_branch(repository)

            @output += repository.checkout(branch_name, new_branch: new_branch)

            if @tag_name
              @output += repository.delete_tag(@tag_name)
            else
              if @directory
                @directory.each_child do |f|
                  @output += repository.add_file(f.basename, f.read) if f.file?
                end
              elsif @files
                @files.each do |f|
                  repository.add_file(f[:name], f[:content])
                end
              else
                @output += repository.add_file(file_name, file_content)
              end

              @output += commit_to repository
              @output += repository.push_changes("#{branch_name}:#{remote_branch}", push_options: @merge_request_push_options)
            end

            repository.delete_ssh_key
          end
        end

        private

        def default_branch(repository)
          repository.remote_branches.last || Runtime::Env.default_branch
        end

        def commit_to(repository)
          @gpg_key_id.nil? ? repository.commit(@commit_message) : repository.commit_with_gpg(@commit_message)
        end
      end
    end
  end
end
