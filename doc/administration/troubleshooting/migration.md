# Migrations problems

## Legacy upload migration

> Introduced in GitLab 12.0.

  The migration takes all attachments uploaded by legacy `AttachmentUploader` and
  migrate them to the path that current uploaders expect.

Although it should not usually happen there could possibly be some attachments belonging to
LegacyDiffNotes. These attachments can't be seen before running the migration by users and
they should not be present in your instance.

However, if you have some of them, you will need to handle them manually.
You can find the ids of failed notes in logs as "MigrateLegacyUploads: LegacyDiffNote"

1. Run a Rails console:

    ```sh
    sudo gitlab-rails console production
    ```

    or for source installs:

    ```sh
    bundle exec rails console production
    ```

 1. Check the failed upload and find the note (you can see their ids in the logs)

    ```ruby
    upload = Upload.find(upload_id)
    note = Note.find(note_id)
    ```


 1. Check the path - it should contain `system/note/attachment`

    ```ruby
    upload.absolut_path
    ```
    
 1. Check the path in the uploader - it should differ from the upload path and should contain  `system/legacy_diff_note`
 
    ```ruby
    uploader = upload.build_uploader
    uploader.file
    ```
    
 1. First, you need to move the file to the path that is expected from the uploader

    ```ruby
    old_path = upload.absolute_path
    new_path = upload.absolute_path.sub('-/system/note/attachment', '-/system/legacy_diff_note')
    new_dir = File.dirname(new_path)
    FileUtils.mkdir_p(new_dir)
    
    FileUtils.mv(old_path, new_path)
    ```

 1. You then need to move the file to the `FileUploader` and create a new `Upload` object
 
    ```ruby
    file_uploader = UploadService.new(note.project, File.read(new_path)).execute
    ```
 
 1. And update the legacy note to contain the file.
 
    ```ruby
    new_text = "#{note.note} \n #{file_uploader.markdown_link}"
    note.update!(
      note: new_text
    )
    ```

 1. And finally, you can remove the old upload
 
    ```ruby
    upload.destroy
    ```

If you have any problems feel free to contact [GitLab Support](https://about.gitlab.com/support/).
