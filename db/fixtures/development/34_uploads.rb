# frozen_string_literal: true

# This seeder seeds comments as well, because uploads are not relevant by
# themselves
Gitlab::Seeder.quiet do
  upload_seed_total_limit = 50
  upload_seed_individual_limit = upload_seed_total_limit / 10

  Issue.limit(upload_seed_individual_limit).find_each do |issue|
    project = issue.project

    project.team.users.limit(upload_seed_individual_limit).each do |user|
      file = CarrierWaveStringFile.new_file(
        file_content: "seeded upload file in project #{project.full_path}, issue #{issue.iid}",
        filename: 'seeded_upload.txt',
        content_type: 'text/plain'
      )

      uploader = UploadService.new(project, file, FileUploader).execute

      note_params = {
        noteable_type: 'Issue',
        noteable_id: issue.id,
        note: "Seeded upload: #{uploader.to_h[:markdown]}",
      }

      Gitlab::ExclusiveLease.skipping_transaction_check do
        Notes::CreateService.new(project, user, note_params).execute
      end
      print '.'
    end
  end

  MergeRequest.limit(upload_seed_individual_limit).find_each do |mr|
    project = mr.project

    project.team.users.limit(upload_seed_individual_limit).each do |user|
      file = CarrierWaveStringFile.new_file(
        file_content: "seeded upload file in project #{project.full_path}, MR #{mr.iid}",
        filename: 'seeded_upload.txt',
        content_type: 'text/plain'
      )

      uploader = UploadService.new(project, file, FileUploader).execute

      note_params = {
        noteable_type: 'MergeRequest',
        noteable_id: mr.id,
        note: "Seeded upload: #{uploader.to_h[:markdown]}",
      }

      Gitlab::ExclusiveLease.skipping_transaction_check do
        Notes::CreateService.new(project, user, note_params).execute
      end
      print '.'
    end
  end
end
