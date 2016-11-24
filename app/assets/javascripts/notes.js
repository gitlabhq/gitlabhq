/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, no-use-before-define, camelcase, no-unused-expressions, quotes, max-len, one-var, one-var-declaration-per-line, default-case, prefer-template, no-undef, consistent-return, no-alert, no-return-assign, no-param-reassign, prefer-arrow-callback, no-else-return, comma-dangle, no-new, brace-style, no-lonely-if, vars-on-top, no-unused-vars, semi, indent, no-sequences, no-shadow, newline-per-chained-call, no-useless-escape, radix, padded-blocks, max-len */

/*= require autosave */
/*= require autosize */
/*= require dropzone */
/*= require dropzone_input */
/*= require gfm_auto_complete */
/*= require jquery.atwho */
/*= require task_list */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Notes = (function() {
    const MAX_VISIBLE_COMMIT_LIST_COUNT = 3;

    Notes.interval = null;

    function Notes(notes_url, note_ids, last_fetched_at, view) {
      this.updateTargetButtons = bind(this.updateTargetButtons, this);
      this.updateCloseButton = bind(this.updateCloseButton, this);
      this.visibilityChange = bind(this.visibilityChange, this);
      this.cancelDiscussionForm = bind(this.cancelDiscussionForm, this);
      this.addDiffNote = bind(this.addDiffNote, this);
      this.setupDiscussionNoteForm = bind(this.setupDiscussionNoteForm, this);
      this.replyToDiscussionNote = bind(this.replyToDiscussionNote, this);
      this.removeNote = bind(this.removeNote, this);
      this.cancelEdit = bind(this.cancelEdit, this);
      this.updateNote = bind(this.updateNote, this);
      this.addDiscussionNote = bind(this.addDiscussionNote, this);
      this.addNoteError = bind(this.addNoteError, this);
      this.addNote = bind(this.addNote, this);
      this.resetMainTargetForm = bind(this.resetMainTargetForm, this);
      this.refresh = bind(this.refresh, this);
      this.keydownNoteText = bind(this.keydownNoteText, this);
      this.toggleCommitList = bind(this.toggleCommitList, this);
      this.notes_url = notes_url;
      this.note_ids = note_ids;
      this.last_fetched_at = last_fetched_at;
      this.view = view;
      this.noteable_url = document.URL;
      this.notesCountBadge || (this.notesCountBadge = $(".issuable-details").find(".notes-tab .badge"));
      this.basePollingInterval = 15000;
      this.maxPollingSteps = 4;
      this.cleanBinding();
      this.addBinding();
      this.setPollingInterval();
      this.setupMainTargetNoteForm();
      this.initTaskList();
      this.collapseLongCommitList();
    }

    Notes.prototype.addBinding = function() {
      // add note to UI after creation
      $(document).on("ajax:success", ".js-main-target-form", this.addNote);
      $(document).on("ajax:success", ".js-discussion-note-form", this.addDiscussionNote);
      // catch note ajax errors
      $(document).on("ajax:error", ".js-main-target-form", this.addNoteError);
      // change note in UI after update
      $(document).on("ajax:success", "form.edit-note", this.updateNote);
      // Edit note link
      $(document).on("click", ".js-note-edit", this.showEditForm);
      $(document).on("click", ".note-edit-cancel", this.cancelEdit);
      // Reopen and close actions for Issue/MR combined with note form submit
      $(document).on("click", ".js-comment-button", this.updateCloseButton);
      $(document).on("keyup input", ".js-note-text", this.updateTargetButtons);
      // resolve a discussion
      $(document).on('click', '.js-comment-resolve-button', this.resolveDiscussion);
      // remove a note (in general)
      $(document).on("click", ".js-note-delete", this.removeNote);
      // delete note attachment
      $(document).on("click", ".js-note-attachment-delete", this.removeAttachment);
      // reset main target form after submit
      $(document).on("ajax:complete", ".js-main-target-form", this.reenableTargetFormSubmitButton);
      $(document).on("ajax:success", ".js-main-target-form", this.resetMainTargetForm);
      // reset main target form when clicking discard
      $(document).on("click", ".js-note-discard", this.resetMainTargetForm);
      // update the file name when an attachment is selected
      $(document).on("change", ".js-note-attachment-input", this.updateFormAttachment);
      // reply to diff/discussion notes
      $(document).on("click", ".js-discussion-reply-button", this.replyToDiscussionNote);
      // add diff note
      $(document).on("click", ".js-add-diff-note-button", this.addDiffNote);
      // hide diff note form
      $(document).on("click", ".js-close-discussion-note-form", this.cancelDiscussionForm);
      // toggle commit list
      $(document).on("click", '.system-note-commit-list-toggler', this.toggleCommitList);
      // fetch notes when tab becomes visible
      $(document).on("visibilitychange", this.visibilityChange);
      // when issue status changes, we need to refresh data
      $(document).on("issuable:change", this.refresh);

      // when a key is clicked on the notes
      return $(document).on("keydown", ".js-note-text", this.keydownNoteText);
    };

    Notes.prototype.cleanBinding = function() {
      $(document).off("ajax:success", ".js-main-target-form");
      $(document).off("ajax:success", ".js-discussion-note-form");
      $(document).off("ajax:success", "form.edit-note");
      $(document).off("click", ".js-note-edit");
      $(document).off("click", ".note-edit-cancel");
      $(document).off("click", ".js-note-delete");
      $(document).off("click", ".js-note-attachment-delete");
      $(document).off("ajax:complete", ".js-main-target-form");
      $(document).off("ajax:success", ".js-main-target-form");
      $(document).off("click", ".js-discussion-reply-button");
      $(document).off("click", ".js-add-diff-note-button");
      $(document).off("visibilitychange");
      $(document).off("keyup", ".js-note-text");
      $(document).off("click", ".js-note-target-reopen");
      $(document).off("click", ".js-note-target-close");
      $(document).off("click", ".js-note-discard");
      $(document).off("keydown", ".js-note-text");
      $(document).off('click', '.js-comment-resolve-button');
      $(document).off("click", '.system-note-commit-list-toggler');
      $('.note .js-task-list-container').taskList('disable');
      return $(document).off('tasklist:changed', '.note .js-task-list-container');
    };

    Notes.prototype.keydownNoteText = function(e) {
      var $textarea, discussionNoteForm, editNote, myLastNote, myLastNoteEditBtn, newText, originalText;
      if (gl.utils.isMetaKey(e)) {
        return;
      }

      $textarea = $(e.target);
      // Edit previous note when UP arrow is hit
      switch (e.which) {
        case 38:
          if ($textarea.val() !== '') {
            return;
          }
          myLastNote = $("li.note[data-author-id='" + gon.current_user_id + "'][data-editable]:last");
          if (myLastNote.length) {
            myLastNoteEditBtn = myLastNote.find('.js-note-edit');
            return myLastNoteEditBtn.trigger('click', [true, myLastNote]);
          }
          break;
        // Cancel creating diff note or editing any note when ESCAPE is hit
        case 27:
          discussionNoteForm = $textarea.closest('.js-discussion-note-form');
          if (discussionNoteForm.length) {
            if ($textarea.val() !== '') {
              if (!confirm('Are you sure you want to cancel creating this comment?')) {
                return;
              }
            }
            this.removeDiscussionNoteForm(discussionNoteForm);
            return;
          }
          editNote = $textarea.closest('.note');
          if (editNote.length) {
            originalText = $textarea.closest('form').data('original-note');
            newText = $textarea.val();
            if (originalText !== newText) {
              if (!confirm('Are you sure you want to cancel editing this comment?')) {
                return;
              }
            }
            return this.removeNoteEditForm(editNote);
          }
      }
    };

    Notes.prototype.initRefresh = function() {
      clearInterval(Notes.interval);
      return Notes.interval = setInterval((function(_this) {
        return function() {
          return _this.refresh();
        };
      })(this), this.pollingInterval);
    };

    Notes.prototype.refresh = function() {
      if (!document.hidden && document.URL.indexOf(this.noteable_url) === 0) {
        return this.getContent();
      }
    };

    Notes.prototype.getContent = function() {
      if (this.refreshing) {
        return;
      }
      this.refreshing = true;
      return $.ajax({
        url: this.notes_url,
        data: "last_fetched_at=" + this.last_fetched_at,
        dataType: "json",
        success: (function(_this) {
          return function(data) {
            var notes;
            notes = data.notes;
            _this.last_fetched_at = data.last_fetched_at;
            _this.setPollingInterval(data.notes.length);
            return $.each(notes, function(i, note) {
              if (note.discussion_html != null) {
                return _this.renderDiscussionNote(note);
              } else {
                return _this.renderNote(note);
              }
            });
          };
        })(this)
      }).always((function(_this) {
        return function() {
          return _this.refreshing = false;
        };
      })(this));
    };


    /*
    Increase @pollingInterval up to 120 seconds on every function call,
    if `shouldReset` has a truthy value, 'null' or 'undefined' the variable
    will reset to @basePollingInterval.

    Note: this function is used to gradually increase the polling interval
    if there aren't new notes coming from the server
     */

    Notes.prototype.setPollingInterval = function(shouldReset) {
      var nthInterval;
      if (shouldReset == null) {
        shouldReset = true;
      }
      nthInterval = this.basePollingInterval * Math.pow(2, this.maxPollingSteps - 1);
      if (shouldReset) {
        this.pollingInterval = this.basePollingInterval;
      } else if (this.pollingInterval < nthInterval) {
        this.pollingInterval *= 2;
      }
      return this.initRefresh();
    };


    /*
    Render note in main comments area.

    Note: for rendering inline notes use renderDiscussionNote
     */

    Notes.prototype.renderNote = function(note) {
      var $notesList, votesBlock;
      if (!note.valid) {
        if (note.award) {
          new Flash('You have already awarded this emoji!', 'alert', this.parentTimeline);
        }
        else {
          if (note.errors.commands_only) {
            new Flash(note.errors.commands_only, 'notice', this.parentTimeline);
            this.refresh();
          }
        }
        return;
      }
      if (note.award) {
        votesBlock = $('.js-awards-block').eq(0);
        gl.awardsHandler.addAwardToEmojiBar(votesBlock, note.name);
        return gl.awardsHandler.scrollToAwards();
      // render note if it not present in loaded list
      // or skip if rendered
      } else if (this.isNewNote(note)) {
        this.note_ids.push(note.id);
        $notesList = $('ul.main-notes-list');
        $notesList.append(note.html).syntaxHighlight();
        // Update datetime format on the recent note
        gl.utils.localTimeAgo($notesList.find("#note_" + note.id + " .js-timeago"), false);
        this.collapseLongCommitList();
        this.initTaskList();
        this.refresh();
        return this.updateNotesCount(1);
      }
    };


    /*
    Check if note does not exists on page
     */

    Notes.prototype.isNewNote = function(note) {
      return $.inArray(note.id, this.note_ids) === -1;
    };

    Notes.prototype.isParallelView = function() {
      return this.view === 'parallel';
    };


    /*
    Render note in discussion area.

    Note: for rendering inline notes use renderDiscussionNote
     */

    Notes.prototype.renderDiscussionNote = function(note) {
      var discussionContainer, form, note_html, row;
      if (!this.isNewNote(note)) {
        return;
      }
      this.note_ids.push(note.id);
      form = $("#new-discussion-note-form-" + note.discussion_id);
      if ((note.original_discussion_id != null) && form.length === 0) {
        form = $("#new-discussion-note-form-" + note.original_discussion_id);
      }
      row = form.closest("tr");
      note_html = $(note.html);
      note_html.syntaxHighlight();
      // is this the first note of discussion?
      discussionContainer = $(".notes[data-discussion-id='" + note.discussion_id + "']");
      if ((note.original_discussion_id != null) && discussionContainer.length === 0) {
        discussionContainer = $(".notes[data-discussion-id='" + note.original_discussion_id + "']");
      }
      if (discussionContainer.length === 0) {
        // insert the note and the reply button after the temp row
        row.after(note.diff_discussion_html);
        // remove the note (will be added again below)
        row.next().find(".note").remove();
        // Before that, the container didn't exist
        discussionContainer = $(".notes[data-discussion-id='" + note.discussion_id + "']");
        // Add note to 'Changes' page discussions
        discussionContainer.append(note_html);
        // Init discussion on 'Discussion' page if it is merge request page
        if ($('body').attr('data-page').indexOf('projects:merge_request') === 0) {
          $('ul.main-notes-list').append(note.discussion_html).syntaxHighlight();
        }
      } else {
        // append new note to all matching discussions
        discussionContainer.append(note_html);
      }

      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        gl.diffNotesCompileComponents();
      }

      gl.utils.localTimeAgo($('.js-timeago', note_html), false);
      return this.updateNotesCount(1);
    };


    /*
    Called in response the main target form has been successfully submitted.

    Removes any errors.
    Resets text and preview.
    Resets buttons.
     */

    Notes.prototype.resetMainTargetForm = function(e) {
      var form;
      form = $(".js-main-target-form");
      // remove validation errors
      form.find(".js-errors").remove();
      // reset text and preview
      form.find(".js-md-write-button").click();
      form.find(".js-note-text").val("").trigger("input");
      form.find(".js-note-text").data("autosave").reset();

      var event = document.createEvent('Event');
      event.initEvent('autosize:update', true, false);
      form.find('.js-autosize')[0].dispatchEvent(event);

      this.updateTargetButtons(e);
    };

    Notes.prototype.reenableTargetFormSubmitButton = function() {
      var form;
      form = $(".js-main-target-form");
      return form.find(".js-note-text").trigger("input");
    };


    /*
    Shows the main form and does some setup on it.

    Sets some hidden fields in the form.
     */

    Notes.prototype.setupMainTargetNoteForm = function() {
      var form;
      // find the form
      form = $(".js-new-note-form");
      // Set a global clone of the form for later cloning
      this.formClone = form.clone();
      // show the form
      this.setupNoteForm(form);
      // fix classes
      form.removeClass("js-new-note-form");
      form.addClass("js-main-target-form");
      form.find("#note_line_code").remove();
      form.find("#note_position").remove();
      form.find("#note_type").remove();
      form.find('.js-comment-resolve-button').closest('comment-and-resolve-btn').remove();
      return this.parentTimeline = form.parents('.timeline');
    };


    /*
    General note form setup.

    deactivates the submit button when text is empty
    hides the preview button when text is empty
    setup GFM auto complete
    show the form
     */

    Notes.prototype.setupNoteForm = function(form) {
      var textarea;
      new GLForm(form);
      textarea = form.find(".js-note-text");
      return new Autosave(textarea, ["Note", form.find("#note_noteable_type").val(), form.find("#note_noteable_id").val(), form.find("#note_commit_id").val(), form.find("#note_type").val(), form.find("#note_line_code").val(), form.find("#note_position").val()]);
    };


    /*
    Called in response to the new note form being submitted

    Adds new note to list.
     */

    Notes.prototype.addNote = function(xhr, note, status) {
      return this.renderNote(note);
    };

    Notes.prototype.addNoteError = function(xhr, note, status) {
      return new Flash('Your comment could not be submitted! Please check your network connection and try again.', 'alert', this.parentTimeline);
    };


    /*
    Called in response to the new note form being submitted

    Adds new note to list.
     */

    Notes.prototype.addDiscussionNote = function(xhr, note, status) {
      var $form = $(xhr.target);

      if ($form.attr('data-resolve-all') != null) {
        var projectPath = $form.data('project-path');
        var discussionId = $form.data('discussion-id');
        var mergeRequestId = $form.data('noteable-iid');

        if (ResolveService != null) {
          ResolveService.toggleResolveForDiscussion(projectPath, mergeRequestId, discussionId);
        }
      }

      this.renderDiscussionNote(note);
      // cleanup after successfully creating a diff/discussion note
      this.removeDiscussionNoteForm($form);
    };


    /*
    Called in response to the edit note form being submitted

    Updates the current note field.
     */

    Notes.prototype.updateNote = function(_xhr, note, _status) {
      var $html, $note_li;
      // Convert returned HTML to a jQuery object so we can modify it further
      $html = $(note.html);
      gl.utils.localTimeAgo($('.js-timeago', $html));
      $html.syntaxHighlight();
      $html.find('.js-task-list-container').taskList('enable');
      // Find the note's `li` element by ID and replace it with the updated HTML
      $note_li = $('.note-row-' + note.id);

      $note_li.replaceWith($html);

      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        gl.diffNotesCompileComponents();
      }
    };


    /*
    Called in response to clicking the edit note link

    Replaces the note text with the note edit form
    Adds a data attribute to the form with the original content of the note for cancellations
     */

    Notes.prototype.showEditForm = function(e, scrollTo, myLastNote) {
      var $noteText, done, form, note;
      e.preventDefault();
      note = $(this).closest(".note");
      note.addClass("is-editting");
      form = note.find(".note-edit-form");
      form.addClass('current-note-edit-form');
      // Show the attachment delete link
      note.find(".js-note-attachment-delete").show();
      done = function($noteText) {
        var noteTextVal;
        // Neat little trick to put the cursor at the end
        noteTextVal = $noteText.val();
        // Store the original note text in a data attribute to retrieve if a user cancels edit.
        form.find('form.edit-note').data('original-note', noteTextVal);
        return $noteText.val('').val(noteTextVal);
      };
      new GLForm(form);
      if ((scrollTo != null) && (myLastNote != null)) {
        // scroll to the bottom
        // so the open of the last element doesn't make a jump
        $('html, body').scrollTop($(document).height());
        return $('html, body').animate({
          scrollTop: myLastNote.offset().top - 150
        }, 500, function() {
          var $noteText;
          $noteText = form.find(".js-note-text");
          $noteText.focus();
          return done($noteText);
        });
      } else {
        $noteText = form.find('.js-note-text');
        $noteText.focus();
        return done($noteText);
      }
    };


    /*
    Called in response to clicking the edit note link

    Hides edit form and restores the original note text to the editor textarea.
     */

    Notes.prototype.cancelEdit = function(e) {
      var note;
      e.preventDefault();
      note = $(e.target).closest('.note');
      return this.removeNoteEditForm(note);
    };

    Notes.prototype.removeNoteEditForm = function(note) {
      var form;
      form = note.find(".current-note-edit-form");
      note.removeClass("is-editting");
      form.removeClass("current-note-edit-form");
      // Replace markdown textarea text with original note text.
      return form.find(".js-note-text").val(form.find('form.edit-note').data('original-note'));
    };


    /*
    Called in response to deleting a note of any kind.

    Removes the actual note from view.
    Removes the whole discussion if the last note is being removed.
     */

    Notes.prototype.removeNote = function(e) {
      var noteId;
      noteId = $(e.currentTarget).closest(".note").attr("id");
      $(".note[id='" + noteId + "']").each((function(_this) {
        // A same note appears in the "Discussion" and in the "Changes" tab, we have
        // to remove all. Using $(".note[id='noteId']") ensure we get all the notes,
        // where $("#noteId") would return only one.
        return function(i, el) {
          var note, notes;
          note = $(el);
          notes = note.closest(".notes");

          if (typeof gl.diffNotesCompileComponents !== 'undefined') {
            if (gl.diffNoteApps[noteId]) {
              gl.diffNoteApps[noteId].$destroy();
            }
          }

          // check if this is the last note for this line
          if (notes.find(".note").length === 1) {
            // "Discussions" tab
            notes.closest(".timeline-entry").remove();
            // "Changes" tab / commit view
            notes.closest("tr").remove();
          }
          return note.remove();
        };
      })(this));
      // Decrement the "Discussions" counter only once
      return this.updateNotesCount(-1);
    };


    /*
    Called in response to clicking the delete attachment link

    Removes the attachment wrapper view, including image tag if it exists
    Resets the note editing form
     */

    Notes.prototype.removeAttachment = function() {
      var note;
      note = $(this).closest(".note");
      note.find(".note-attachment").remove();
      note.find(".note-body > .note-text").show();
      note.find(".note-header").show();
      return note.find(".current-note-edit-form").remove();
    };


    /*
    Called when clicking on the "reply" button for a diff line.

    Shows the note form below the notes.
     */

    Notes.prototype.replyToDiscussionNote = function(e) {
      var form, replyLink;
      form = this.formClone.clone();
      replyLink = $(e.target).closest(".js-discussion-reply-button");
      // insert the form after the button
      replyLink
        .closest('.discussion-reply-holder')
        .hide()
        .after(form);
      // show the form
      return this.setupDiscussionNoteForm(replyLink, form);
    };


    /*
    Shows the diff or discussion form and does some setup on it.

    Sets some hidden fields in the form.

    Note: dataHolder must have the "discussionId", "lineCode", "noteableType"
    and "noteableId" data attributes set.
     */

    Notes.prototype.setupDiscussionNoteForm = function(dataHolder, form) {
      // setup note target
      form.attr('id', "new-discussion-note-form-" + (dataHolder.data("discussionId")));
      form.attr("data-line-code", dataHolder.data("lineCode"));
      form.find("#note_type").val(dataHolder.data("noteType"));
      form.find("#line_type").val(dataHolder.data("lineType"));
      form.find("#note_commit_id").val(dataHolder.data("commitId"));
      form.find("#note_line_code").val(dataHolder.data("lineCode"));
      form.find("#note_position").val(dataHolder.attr("data-position"));
      form.find("#note_noteable_type").val(dataHolder.data("noteableType"));
      form.find("#note_noteable_id").val(dataHolder.data("noteableId"));
      form.find('.js-note-discard').show().removeClass('js-note-discard').addClass('js-close-discussion-note-form').text(form.find('.js-close-discussion-note-form').data('cancel-text'));
      form.find('.js-note-target-close').remove();
      this.setupNoteForm(form);

      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        var $commentBtn = form.find('comment-and-resolve-btn');
        $commentBtn
          .attr(':discussion-id', "'" + dataHolder.data('discussionId') + "'");

        gl.diffNotesCompileComponents();
      }

      form.find(".js-note-text").focus();
      form
        .find('.js-comment-resolve-button')
        .attr('data-discussion-id', dataHolder.data('discussionId'));
      form
        .removeClass('js-main-target-form')
        .addClass("discussion-form js-discussion-note-form");
    };


    /*
    Called when clicking on the "add a comment" button on the side of a diff line.

    Inserts a temporary row for the form below the line.
    Sets up the form and shows it.
     */

    Notes.prototype.addDiffNote = function(e) {
      var $link, addForm, hasNotes, lineType, newForm, nextRow, noteForm, notesContent, replyButton, row, rowCssToAdd, targetContent;
      e.preventDefault();
      $link = $(e.currentTarget);
      row = $link.closest("tr");
      nextRow = row.next();
      hasNotes = nextRow.is(".notes_holder");
      addForm = false;
      notesContentSelector = ".notes_content";
      rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\" colspan=\"2\"></td><td class=\"notes_content\"><div class=\"content\"></div></td></tr>";
      // In parallel view, look inside the correct left/right pane
      if (this.isParallelView()) {
        lineType = $link.data("lineType");
        notesContentSelector += "." + lineType;
        rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line old\"></td><td class=\"notes_content parallel old\"><div class=\"content\"></div></td><td class=\"notes_line new\"></td><td class=\"notes_content parallel new\"><div class=\"content\"></div></td></tr>";
      }
      notesContentSelector += " .content";
      if (hasNotes) {
        nextRow.show();
        notesContent = nextRow.find(notesContentSelector);
        if (notesContent.length) {
          notesContent.show();
          replyButton = notesContent.find(".js-discussion-reply-button:visible");
          if (replyButton.length) {
            e.target = replyButton[0];
            $.proxy(this.replyToDiscussionNote, replyButton[0], e).call();
          } else {
            // In parallel view, the form may not be present in one of the panes
            noteForm = notesContent.find(".js-discussion-note-form");
            if (noteForm.length === 0) {
              addForm = true;
            }
          }
        }
      } else {
        // add a notes row and insert the form
        row.after(rowCssToAdd);
        nextRow = row.next();
        notesContent = nextRow.find(notesContentSelector);
        addForm = true;
      }
      if (addForm) {
        newForm = this.formClone.clone();
        newForm.appendTo(notesContent);
        // show the form
        return this.setupDiscussionNoteForm($link, newForm);
      }
    };


    /*
    Called in response to "cancel" on a diff note form.

    Shows the reply button again.
    Removes the form and if necessary it's temporary row.
     */

    Notes.prototype.removeDiscussionNoteForm = function(form) {
      var glForm, row;
      row = form.closest("tr");
      glForm = form.data('gl-form');
      glForm.destroy();
      form.find(".js-note-text").data("autosave").reset();
      // show the reply button (will only work for replies)
      form
        .prev('.discussion-reply-holder')
        .show();
      if (row.is(".js-temp-notes-holder")) {
        // remove temporary row for diff lines
        return row.remove();
      } else {
        // only remove the form
        return form.remove();
      }
    };

    Notes.prototype.cancelDiscussionForm = function(e) {
      var form;
      e.preventDefault();
      form = $(e.target).closest(".js-discussion-note-form");
      return this.removeDiscussionNoteForm(form);
    };


    /*
    Called after an attachment file has been selected.

    Updates the file name for the selected attachment.
     */

    Notes.prototype.updateFormAttachment = function() {
      var filename, form;
      form = $(this).closest("form");
      // get only the basename
      filename = $(this).val().replace(/^.*[\\\/]/, "");
      return form.find(".js-attachment-filename").text(filename);
    };


    /*
    Called when the tab visibility changes
     */

    Notes.prototype.visibilityChange = function() {
      return this.refresh();
    };

    Notes.prototype.updateCloseButton = function(e) {
      var closebtn, form, textarea;
      textarea = $(e.target);
      form = textarea.parents('form');
      closebtn = form.find('.js-note-target-close');
      return closebtn.text(closebtn.data('original-text'));
    };

    Notes.prototype.updateTargetButtons = function(e) {
      var closebtn, closetext, discardbtn, form, reopenbtn, reopentext, textarea;
      textarea = $(e.target);
      form = textarea.parents('form');
      reopenbtn = form.find('.js-note-target-reopen');
      closebtn = form.find('.js-note-target-close');
      discardbtn = form.find('.js-note-discard');
      if (textarea.val().trim().length > 0) {
        reopentext = reopenbtn.data('alternative-text');
        closetext = closebtn.data('alternative-text');
        if (reopenbtn.text() !== reopentext) {
          reopenbtn.text(reopentext);
        }
        if (closebtn.text() !== closetext) {
          closebtn.text(closetext);
        }
        if (reopenbtn.is(':not(.btn-comment-and-reopen)')) {
          reopenbtn.addClass('btn-comment-and-reopen');
        }
        if (closebtn.is(':not(.btn-comment-and-close)')) {
          closebtn.addClass('btn-comment-and-close');
        }
        if (discardbtn.is(':hidden')) {
          return discardbtn.show();
        }
      } else {
        reopentext = reopenbtn.data('original-text');
        closetext = closebtn.data('original-text');
        if (reopenbtn.text() !== reopentext) {
          reopenbtn.text(reopentext);
        }
        if (closebtn.text() !== closetext) {
          closebtn.text(closetext);
        }
        if (reopenbtn.is('.btn-comment-and-reopen')) {
          reopenbtn.removeClass('btn-comment-and-reopen');
        }
        if (closebtn.is('.btn-comment-and-close')) {
          closebtn.removeClass('btn-comment-and-close');
        }
        if (discardbtn.is(':visible')) {
          return discardbtn.hide();
        }
      }
    };

    Notes.prototype.initTaskList = function() {
      this.enableTaskList();
      return $(document).on('tasklist:changed', '.note .js-task-list-container', this.updateTaskList);
    };

    Notes.prototype.enableTaskList = function() {
      return $('.note .js-task-list-container').taskList('enable');
    };

    Notes.prototype.updateTaskList = function() {
      return $('form', this).submit();
    };

    Notes.prototype.updateNotesCount = function(updateCount) {
      return this.notesCountBadge.text(parseInt(this.notesCountBadge.text()) + updateCount);
    };

    Notes.prototype.resolveDiscussion = function() {
      var $this = $(this);
      var discussionId = $this.attr('data-discussion-id');

      $this
        .closest('form')
        .attr('data-discussion-id', discussionId)
        .attr('data-resolve-all', 'true')
        .attr('data-project-path', $this.attr('data-project-path'));
    };

    Notes.prototype.toggleCommitList = function(e) {
      const $element = $(e.target);
      const $closestSystemCommitList = $element.siblings('.system-note-commit-list');

      $closestSystemCommitList.toggleClass('hide-shade');
    };

    /**
    Scans system notes with `ul` elements in system note body
    then collapse long commit list pushed by user to make it less
    intrusive.
     */
    Notes.prototype.collapseLongCommitList = function() {
      const systemNotes = $('#notes-list').find('li.system-note').has('ul');

      $.each(systemNotes, function(index, systemNote) {
        const $systemNote = $(systemNote);
        const headerMessage = $systemNote.find('.note-text').find('p:first').text().replace(':', '');

        $systemNote.find('.note-header .system-note-message').html(headerMessage);

        if ($systemNote.find('li').length > MAX_VISIBLE_COMMIT_LIST_COUNT) {
          $systemNote.find('.note-text').addClass('system-note-commit-list');
          $systemNote.find('.system-note-commit-list-toggler').show();
        } else {
          $systemNote.find('.note-text').addClass('system-note-commit-list hide-shade');
        }
      });
    };

    return Notes;

  })();

}).call(this);
