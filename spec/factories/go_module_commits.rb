# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_commit, class: 'Commit' do
    skip_create

    transient do
      files { { 'foo.txt' => 'content' } }
      message { 'Message' }
      # rubocop: disable FactoryBot/InlineAssociation
      # We need a persisted project so we can create commits and tags
      # in `commit` otherwise linting this factory with `build` strategy
      # will fail.
      project { create(:project, :repository) }
      # rubocop: enable FactoryBot/InlineAssociation

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
        message { 'Add files' }
      end
    end

    trait :package do
      transient do
        path { 'pkg' }
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
        path { "#{name}/" }

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
