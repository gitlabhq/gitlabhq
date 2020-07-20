# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_commit, class: 'Commit' do
    skip_create

    transient do
      files { { 'foo.txt' => 'content' } }
      message { 'Message' }
      project { create(:project, :repository) }

      service do
        Files::MultiService.new(
          project,
          project.owner,
          commit_message: message,
          start_branch: project.repository.root_ref || 'master',
          branch_name: project.repository.root_ref || 'master',
          actions: files.map do |path, content|
            { action: :create, file_path: path, content: content }
          end
        )
      end

      tag { nil }
      tag_message { nil }

      commit do
        r = service.execute

        raise "operation failed: #{r}" unless r[:status] == :success

        commit = project.repository.commit_by(oid: r[:result])

        if tag
          r = Tags::CreateService.new(project, project.owner).execute(tag, commit.sha, tag_message)

          raise "operation failed: #{r}" unless r[:status] == :success
        end

        commit
      end
    end

    trait :files do
      transient do
        files { raise ArgumentError.new("files is required") }
        message { 'Add files' }
      end
    end

    trait :package do
      transient do
        path { raise ArgumentError.new("path is required") }
        message { 'Add package' }
        files { { "#{path}/b.go" => "package b\nfunc Bye() { println(\"Goodbye world!\") }\n" } }
      end
    end

    trait :module do
      transient do
        name { nil }
        message { 'Add module' }
        host_prefix { "#{::Gitlab.config.gitlab.host}/#{project.path_with_namespace}" }

        url { name ? "#{host_prefix}/#{name}" : host_prefix }
        path { name.to_s + '/' }

        files do
          {
            "#{path}go.mod" => "module #{url}\n",
            "#{path}a.go" => "package a\nfunc Hi() { println(\"Hello world!\") }\n"
          }
        end
      end
    end

    initialize_with do
      commit
    end
  end
end
