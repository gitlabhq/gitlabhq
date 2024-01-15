# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportLfsObjectsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        # Importer::LfsObjectsImporter can resume work when interrupted as
        # it uses Projects::LfsPointers::LfsObjectDownloadListService which excludes LFS objects that already exist.
        # https://gitlab.com/gitlab-org/gitlab/-/blob/eabf0800/app/services/projects/lfs_pointers/lfs_object_download_list_service.rb#L69-71
        resumes_work_when_interrupted!

        # project - An instance of Project.
        def import(_client, project)
          waiter = Importer::LfsObjectsImporter
            .new(project, nil)
            .execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            'finish'
          )
        end
      end
    end
  end
end
