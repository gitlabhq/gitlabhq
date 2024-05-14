# frozen_string_literal: true

FactoryBot.define do
  factory :design_version, class: 'DesignManagement::Version' do
    sha
    issue { designs.first&.issue || association(:issue) }
    author { issue&.author || association(:user) }

    transient do
      designs_count { 1 }
      created_designs { [] }
      modified_designs { [] }
      deleted_designs { [] }
    end

    trait :importing do
      issue { nil }

      designs_count { 0 }
      importing { true }
    end

    after(:build) do |version, evaluator|
      # By default all designs are created_designs, so just add them.
      specific_designs = [].concat(
        evaluator.created_designs,
        evaluator.modified_designs,
        evaluator.deleted_designs
      )
      version.designs += specific_designs

      unless evaluator.designs_count == 0 || version.designs.present?
        version.designs << create(:design, issue: version.issue)
      end
    end

    after :create do |version, evaluator|
      # FactoryBot does not like methods, so we use lambdas instead
      events = DesignManagement::Action.events

      version.actions
        .where(design_id: evaluator.modified_designs.map(&:id))
        .update_all(event: events[:modification])

      version.actions
        .where(design_id: evaluator.deleted_designs.map(&:id))
        .update_all(event: events[:deletion])

      # Ensure version.issue == design.issue for all version.designs
      version.designs.update_all(issue_id: version.issue_id)
      version.designs.reload

      needed = evaluator.designs_count
      have = version.designs.size

      create_list(:design, [0, needed - have].max, issue: version.issue).each do |d|
        version.designs << d
      end

      version.actions.reset
    end

    # Use this trait to build versions with designs that are backed by Git LFS, committed
    # to the repository, and with an LfsObject correctly created for it.
    trait :with_lfs_file do
      committed

      transient do
        raw_file { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }
        lfs_pointer { Gitlab::Git::LfsPointerFile.new(SecureRandom.random_bytes) }
        file { lfs_pointer.pointer }
      end

      after :create do |version, evaluator|
        lfs_object = create(:lfs_object, file: evaluator.raw_file, oid: evaluator.lfs_pointer.sha256, size: evaluator.lfs_pointer.size)
        create(:lfs_objects_project, project: version.project, lfs_object: lfs_object, repository_type: :design)
      end
    end

    # This trait is for versions that must be present in the git repository.
    trait :committed do
      transient do
        file { File.join(Rails.root, 'spec/fixtures/dk.png') }
      end

      after :create do |version, evaluator|
        project = version.issue.project
        repository = project.design_repository
        repository.create_if_not_exists

        designs = version.designs_by_event
        base_change = { content: evaluator.file }

        actions = %w[modification deletion].flat_map { |k| designs.fetch(k, []) }.map do |design|
          base_change.merge(action: :create, file_path: design.full_path)
        end

        if actions.present?
          repository.commit_files(
            evaluator.author,
            branch_name: 'master',
            message: "created #{actions.size} files",
            actions: actions
          )
        end

        mapping = {
          'creation' => :create,
          'modification' => :update,
          'deletion' => :delete
        }

        version_actions = designs.flat_map do |(event, designs)|
          base = event == 'deletion' ? {} : base_change
          designs.map do |design|
            base.merge(action: mapping[event], file_path: design.full_path)
          end
        end

        sha = repository.commit_files(
          evaluator.author,
          branch_name: 'master',
          message: "edited #{version_actions.size} files",
          actions: version_actions
        )

        version.update!(sha: sha)
      end
    end
  end
end
