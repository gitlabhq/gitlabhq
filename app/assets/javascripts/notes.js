var NoteList = {

  notes_path: null,
  target_params: null,
  target_id: 0,
  target_type: null,

  init: function(tid, tt, path) {
    NoteList.notes_path = path + ".js";
    NoteList.target_id = tid;
    NoteList.target_type = tt;
    NoteList.target_params = "target_type=" + NoteList.target_type + "&target_id=" + NoteList.target_id;

    NoteList.setupMainTargetNoteForm();

    // get initial set of notes
    NoteList.getContent();

    // add a new diff note
    $(document).on("click",
                    ".js-add-diff-note-button",
                    NoteList.addDiffNote);

    // reply to diff/discussion notes
    $(document).on("click",
                    ".js-discussion-reply-button",
                    NoteList.replyToDiscussionNote);

    // setup note preview
    $(document).on("click",
                    ".js-note-preview-button",
                    NoteList.previewNote);

    // update the file name when an attachment is selected
    $(document).on("change",
                   ".js-note-attachment-input",
                   NoteList.updateFormAttachment);

    // hide diff note form
    $(document).on("click",
                    ".js-close-discussion-note-form",
                    NoteList.removeDiscussionNoteForm);

    // remove a note (in general)
    $(document).on("click",
                    ".js-note-delete",
                    NoteList.removeNote);

    // show the edit note form
    $(document).on("click",
                    ".js-note-edit",
                    NoteList.showEditNoteForm);

    // cancel note editing
    $(document).on("click",
                    ".note-edit-cancel",
                    NoteList.cancelNoteEdit);

    // delete note attachment
    $(document).on("click",
                    ".js-note-attachment-delete",
                    NoteList.deleteNoteAttachment);

    // update the note after editing
    $(document).on("ajax:complete",
                   "form.edit_note",
                   NoteList.updateNote);

    // reset main target form after submit
    $(document).on("ajax:complete",
                   ".js-main-target-form",
                   NoteList.resetMainTargetForm);


    $(document).on("click",
                  ".js-choose-note-attachment-button",
                  NoteList.chooseNoteAttachment);

    $(document).on("click",
                  ".js-show-outdated-discussion",
                  function(e) { $(this).next('.outdated-discussion').show(); e.preventDefault() });
  },


  /**
   * When clicking on buttons
   */

  /**
   * Called when clicking on the "add a comment" button on the side of a diff line.
   *
   * Inserts a temporary row for the form below the line.
   * Sets up the form and shows it.
   */
  addDiffNote: function(e) {
    e.preventDefault();

    // find the form
    var form = $(".js-new-note-form");
    var row = $(this).closest("tr");
    var nextRow = row.next();

    // does it already have notes?
    if (nextRow.is(".notes_holder")) {
      $.proxy(NoteList.replyToDiscussionNote,
              nextRow.find(".js-discussion-reply-button")
             ).call();
    } else {
      // add a notes row and insert the form
      row.after('<tr class="notes_holder js-temp-notes-holder"><td class="notes_line" colspan="2"></td><td class="notes_content"></td></tr>');
      form.clone().appendTo(row.next().find(".notes_content"));

      // show the form
      NoteList.setupDiscussionNoteForm($(this), row.next().find("form"));
    }
  },

  /**
   * Called when clicking the "Choose File" button.
   *
   * Opens the file selection dialog.
   */
  chooseNoteAttachment: function() {
    var form = $(this).closest("form");

    form.find(".js-note-attachment-input").click();
  },

  /**
   * Shows the note preview.
   *
   * Lets the server render GFM into Html and displays it.
   *
   * Note: uses the Toggler behavior to toggle preview/edit views/buttons
   */
  previewNote: function(e) {
    e.preventDefault();

    var form = $(this).closest("form");
    var preview = form.find('.js-note-preview');
    var noteText = form.find('.js-note-text').val();

    if(noteText.trim().length === 0) {
      preview.text('Nothing to preview.');
    } else {
      preview.text('Loading...');
      $.post($(this).data('url'), {note: noteText})
        .success(function(previewData) {
          preview.html(previewData);
        });
    }
  },

  /**
   * Called in response to "cancel" on a diff note form.
   *
   * Shows the reply button again.
   * Removes the form and if necessary it's temporary row.
   */
  removeDiscussionNoteForm: function() {
    var form = $(this).closest("form");
    var row = form.closest("tr");

    // show the reply button (will only work for replys)
    form.prev(".js-discussion-reply-button").show();

    if (row.is(".js-temp-notes-holder")) {
      // remove temporary row for diff lines
      row.remove();
    } else {
      // only remove the form
      form.remove();
    }
  },

  /**
   * Called in response to deleting a note of any kind.
   *
   * Removes the actual note from view.
   * Removes the whole discussion if the last note is being removed.
   */
  removeNote: function() {
    var note = $(this).closest(".note");
    var notes = note.closest(".notes");

    // check if this is the last note for this line
    if (notes.find(".note").length === 1) {
      // for discussions
      notes.closest(".discussion").remove();

      // for diff lines
      notes.closest("tr").remove();
    }

    note.remove();
    NoteList.updateVotes();
  },

  /**
   * Called in response to clicking the edit note link
   *
   * Replaces the note text with the note edit form
   * Adds a hidden div with the original content of the note to fill the edit note form with
   * if the user cancels
   */
  showEditNoteForm: function(e) {
    e.preventDefault();
    var note = $(this).closest(".note");
    note.find(".note-text").hide();

    // Show the attachment delete link
    note.find(".js-note-attachment-delete").show();

    var form = note.find(".note-edit-form");
    form.show();


    var textarea = form.find("textarea");
    var p = $("<p></p>").text(textarea.val());
    var hidden_div = $('<div class="note-original-content"></div>').append(p);
    form.append(hidden_div);
    hidden_div.hide();
    textarea.focus();
  },

  /**
   * Called in response to clicking the cancel button when editing a note
   *
   * Resets and hides the note editing form
   */
  cancelNoteEdit: function(e) {
    e.preventDefault();
    var note = $(this).closest(".note");
    NoteList.resetNoteEditing(note);
  },


  /**
   * Called in response to clicking the delete attachment link
   *
   * Removes the attachment wrapper view, including image tag if it exists
   * Resets the note editing form
   */
  deleteNoteAttachment: function() {
    var note = $(this).closest(".note");
    note.find(".note-attachment").remove();
    NoteList.resetNoteEditing(note);
    NoteList.rewriteTimestamp(note.find(".note-last-update"));
  },


  /**
   * Called when clicking on the "reply" button for a diff line.
   *
   * Shows the note form below the notes.
   */
  replyToDiscussionNote: function() {
    // find the form
    var form = $(".js-new-note-form");

    // hide reply button
    $(this).hide();
    // insert the form after the button
    form.clone().insertAfter($(this));

    // show the form
    NoteList.setupDiscussionNoteForm($(this), $(this).next("form"));
  },


  /**
   * Helper for inserting and setting up note forms.
   */


  /**
   * Called in response to creating a note failing validation.
   *
   * Adds the rendered errors to the respective form.
   * If "discussionId" is null or undefined, the main target form is assumed.
   */
  errorsOnForm: function(errorsHtml, discussionId) {
    // find the form
    if (discussionId) {
      var form = $("form[rel='"+discussionId+"']");
    } else {
      var form = $(".js-main-target-form");
    }

    form.find(".js-errors").remove();
    form.prepend(errorsHtml);

    form.find(".js-note-text").focus();
  },


  /**
   * Shows the diff/discussion form and does some setup on it.
   *
   * Sets some hidden fields in the form.
   *
   * Note: dataHolder must have the "discussionId", "lineCode", "noteableType"
   *       and "noteableId" data attributes set.
   */
  setupDiscussionNoteForm: function(dataHolder, form) {
    // setup note target
    form.attr("rel", dataHolder.data("discussionId"));
    form.find("#note_commit_id").val(dataHolder.data("commitId"));
    form.find("#note_line_code").val(dataHolder.data("lineCode"));
    form.find("#note_noteable_type").val(dataHolder.data("noteableType"));
    form.find("#note_noteable_id").val(dataHolder.data("noteableId"));

    NoteList.setupNoteForm(form);

    form.find(".js-note-text").focus();
  },

  /**
   * Shows the main form and does some setup on it.
   *
   * Sets some hidden fields in the form.
   */
  setupMainTargetNoteForm: function() {
    // find the form
    var form = $(".js-new-note-form");
    // insert the form after the button
    form.clone().replaceAll($(".js-main-target-form"));

    form = form.prev("form");

    // show the form
    NoteList.setupNoteForm(form);

    // fix classes
    form.removeClass("js-new-note-form");
    form.addClass("js-main-target-form");

    // remove unnecessary fields and buttons
    form.find("#note_line_code").remove();
    form.find(".js-close-discussion-note-form").remove();
  },

  /**
   * General note form setup.
   *
   * * deactivates the submit button when text is empty
   * * hides the preview button when text is empty
   * * setup GFM auto complete
   * * show the form
   */
  setupNoteForm: function(form) {
    disableButtonIfEmptyField(form.find(".js-note-text"), form.find(".js-comment-button"));

    form.removeClass("js-new-note-form");

    // setup preview buttons
    form.find(".js-note-edit-button, .js-note-preview-button")
        .tooltip({ placement: 'left' });

    previewButton = form.find(".js-note-preview-button");
    form.find(".js-note-text").on("input", function() {
      if ($(this).val().trim() !== "") {
        previewButton.removeClass("turn-off").addClass("turn-on");
      } else {
        previewButton.removeClass("turn-on").addClass("turn-off");
      }
    });

    // remove notify commit author checkbox for non-commit notes
    if (form.find("#note_noteable_type").val() !== "Commit") {
      form.find(".js-notify-commit-author").remove();
    }

    GitLab.GfmAutoComplete.setup();

    form.show();
  },


  /**
   * Handle loading the initial set of notes.
   * And set up loading more notes when scrolling to the bottom of the page.
   */


  /**
   * Gets an initial set of notes.
   */
  getContent: function() {
    $.ajax({
      url: NoteList.notes_path,
      data: NoteList.target_params,
      complete: function(){ $('.js-notes-busy').removeClass("loading")},
      beforeSend: function() { $('.js-notes-busy').addClass("loading") },
      dataType: "script"
    });
  },

  /**
   * Called in response to getContent().
   * Replaces the content of #notes-list with the given html.
   */
  setContent: function(newNoteIds, html) {
    $("#notes-list").html(html);
  },


  /**
   * Adds a single common note to #notes-list.
   */
  appendNewNote: function(id, html) {
    $("#notes-list").append(html);
    NoteList.updateVotes();
  },

  /**
   * Adds a single discussion note to #notes-list.
   *
   * Also removes the corresponding form.
   */
  appendNewDiscussionNote: function(discussionId, diffRowHtml, noteHtml) {
    var form = $("form[rel='"+discussionId+"']");
    var row = form.closest("tr");

    // is this the first note of discussion?
    if (row.is(".js-temp-notes-holder")) {
      // insert the note and the reply button after the temp row
      row.after(diffRowHtml);
      // remove the note (will be added again below)
      row.next().find(".note").remove();
    }

    // append new note to all matching discussions
    $(".notes[rel='"+discussionId+"']").append(noteHtml);

    // cleanup after successfully creating a diff/discussion note
    $.proxy(NoteList.removeDiscussionNoteForm, form).call();
  },

  /**
   * Called in response the main target form has been successfully submitted.
   *
   * Removes any errors.
   * Resets text and preview.
   * Resets buttons.
   */
  resetMainTargetForm: function(){
    var form = $(this);

    // remove validation errors
    form.find(".js-errors").remove();

    // reset text and preview
    var previewContainer = form.find(".js-toggler-container.note_text_and_preview");
    if (previewContainer.is(".on")) {
      previewContainer.removeClass("on");
    }
    form.find(".js-note-text").val("").trigger("input");
  },

  /**
   * Called after an attachment file has been selected.
   *
   * Updates the file name for the selected attachment.
   */
  updateFormAttachment: function() {
    var form = $(this).closest("form");

    // get only the basename
    var filename = $(this).val().replace(/^.*[\\\/]/, '');

    form.find(".js-attachment-filename").text(filename);
  },

  /**
   * Recalculates the votes and updates them (if they are displayed at all).
   *
   * Assumes all relevant notes are displayed (i.e. there are no more notes to
   * load via getMore()).
   * Might produce inaccurate results when not all notes have been loaded and a
   * recalculation is triggered (e.g. when deleting a note).
   */
  updateVotes: function() {
    var votes = $("#votes .votes");
    var notes = $("#notes-list .note .vote");

    // only update if there is a vote display
    if (votes.size()) {
      var upvotes = notes.filter(".upvote").size();
      var downvotes = notes.filter(".downvote").size();
      var votesCount = upvotes + downvotes;
      var upvotesPercent = votesCount ? (100.0 / votesCount * upvotes) : 0;
      var downvotesPercent = votesCount ? (100.0 - upvotesPercent) : 0;

      // change vote bar lengths
      votes.find(".bar-success").css("width", upvotesPercent+"%");
      votes.find(".bar-danger").css("width", downvotesPercent+"%");
      // replace vote numbers
      votes.find(".upvotes").text(votes.find(".upvotes").text().replace(/\d+/, upvotes));
      votes.find(".downvotes").text(votes.find(".downvotes").text().replace(/\d+/, downvotes));
    }
  },

  /**
   * Called in response to the edit note form being submitted
   *
   * Updates the current note field.
   * Hides the edit note form
   */
  updateNote: function(e, xhr, settings) {
    response = JSON.parse(xhr.responseText);
    if (response.success) {
      var note_li = $("#note_" + response.id);
      var note_text = note_li.find(".note-text");
      note_text.html(response.note).show();

      var note_form = note_li.find(".note-edit-form");
      note_form.hide();
      note_form.find(".btn-save").enableButton();

      // Update the "Edited at xxx label" on the note to show it's just been updated
      NoteList.rewriteTimestamp(note_li.find(".note-last-update"));
    }
  },

  /**
  * Called in response to the 'cancel note' link clicked, or after deleting a note attachment
  *
  * Hides the edit note form and shows the note
  * Resets the edit note form textarea with the original content of the note
  */
  resetNoteEditing: function(note) {
    note.find(".note-text").show();

    // Hide the attachment delete link
    note.find(".js-note-attachment-delete").hide();

    // Put the original content of the note back into the edit form textarea
    var form = note.find(".note-edit-form");
    var original_content = form.find(".note-original-content");
    form.find("textarea").val(original_content.text());
    original_content.remove();

    note.find(".note-edit-form").hide();
  },

  /**
  * Utility function to generate new timestamp text for a note
  *
  */
  rewriteTimestamp: function(element) {
    // Strip all newlines from the existing timestamp
    var ts = element.text().replace(/\n/g, ' ').trim();

    // If the timestamp already has '(Edited xxx ago)' text, remove it
    ts = ts.replace(new RegExp("\\(Edited [A-Za-z0-9 ]+\\)$", "gi"), "");

    // Append "(Edited just now)"
    ts = (ts + " <small>(Edited just now)</small>");

    element.html(ts);
  }
};
