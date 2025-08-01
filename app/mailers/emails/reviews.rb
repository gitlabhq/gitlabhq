# frozen_string_literal: true

module Emails
  module Reviews
    def new_review_email(recipient_id, review_id)
      setup_review_email(review_id, recipient_id)

      # NOTE: We must not send any internal notes to users who are not supposed to be able to see it.
      #   Also, we don't want to send an empty email the review only contains internal notes.
      unless @recipient.can?(:read_internal_note, @project)
        @notes = @notes.reject(&:internal?)

        return if @notes.blank?
      end

      mail_answer_thread(@merge_request, review_thread_options)
    end

    private

    def review_thread_options
      {
        from: sender(@author.id),
        to: @recipient.notification_email_for(@merge_request.target_project.group),
        subject: subject("#{@merge_request.title} (#{@merge_request.to_reference})")
      }
    end

    def setup_review_email(review_id, recipient_id)
      @review = Review.find_by_id(review_id)
      @recipient = User.find(recipient_id)
      @notes = @review.notes
      @discussions = Discussion.build_discussions(@review.discussion_ids, preload_note_diff_file: true)
      @include_diff_discussion_stylesheet = @discussions.values.any? do |discussion|
        discussion.diff_discussion? && discussion.on_text?
      end
      @author = @review.author
      @author_name = @review.author_name
      @project = @review.project
      @merge_request = @review.merge_request
      @target_url = project_merge_request_url(@project, @merge_request)
      @sent_notification = SentNotification.record(@merge_request, recipient_id)
    end
  end
end
