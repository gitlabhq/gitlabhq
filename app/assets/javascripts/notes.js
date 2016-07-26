
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
    var isMetaKey;

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
    }

    Notes.prototype.addBinding = function() {
      $(document).on("ajax:success", ".js-main-target-form", this.addNote);
      $(document).on("ajax:success", ".js-discussion-note-form", this.addDiscussionNote);
      $(document).on("ajax:error", ".js-main-target-form", this.addNoteError);
      $(document).on("ajax:success", "form.edit-note", this.updateNote);
      $(document).on("click", ".js-note-edit", this.showEditForm);
      $(document).on("click", ".note-edit-cancel", this.cancelEdit);
      $(document).on("click", ".js-comment-button", this.updateCloseButton);
      $(document).on("keyup input", ".js-note-text", this.updateTargetButtons);
      $(document).on('click', '.js-comment-resolve-button', this.resolveDiscussion);
      $(document).on("click", ".js-note-delete", this.removeNote);
      $(document).on("click", ".js-note-attachment-delete", this.removeAttachment);
      $(document).on("ajax:complete", ".js-main-target-form", this.reenableTargetFormSubmitButton);
      $(document).on("ajax:success", ".js-main-target-form", this.resetMainTargetForm);
      $(document).on("click", ".js-note-discard", this.resetMainTargetForm);
      $(document).on("change", ".js-note-attachment-input", this.updateFormAttachment);
      $(document).on("click", ".js-discussion-reply-button", this.replyToDiscussionNote);
      $(document).on("click", ".js-add-diff-note-button", this.addDiffNote);
      $(document).on("click", ".js-close-discussion-note-form", this.cancelDiscussionForm);
      $(document).on("visibilitychange", this.visibilityChange);
      $(document).on("issuable:change", this.refresh);
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
      $('.note .js-task-list-container').taskList('disable');
      return $(document).off('tasklist:changed', '.note .js-task-list-container');
    };

    Notes.prototype.keydownNoteText = function(e) {
      var $textarea, discussionNoteForm, editNote, myLastNote, myLastNoteEditBtn, newText, originalText;
      if (isMetaKey(e)) {
        return;
      }
      $textarea = $(e.target);
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

    isMetaKey = function(e) {
      return e.metaKey || e.ctrlKey || e.altKey || e.shiftKey;
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
          new Flash('You have already awarded this emoji!', 'alert');
        }
        return;
      }
      if (note.award) {
        votesBlock = $('.js-awards-block').eq(0);
        gl.awardsHandler.addAwardToEmojiBar(votesBlock, note.name);
        return gl.awardsHandler.scrollToAwards();
      } else if (this.isNewNote(note)) {
        this.note_ids.push(note.id);
        $notesList = $('ul.main-notes-list');
        $notesList.append(note.html).syntaxHighlight();
        gl.utils.localTimeAgo($notesList.find("#note_" + note.id + " .js-timeago"), false);
        this.initTaskList();
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
      discussionContainer = $(".notes[data-discussion-id='" + note.discussion_id + "']");
      if ((note.original_discussion_id != null) && discussionContainer.length === 0) {
        discussionContainer = $(".notes[data-discussion-id='" + note.original_discussion_id + "']");
      }
      if (discussionContainer.length === 0) {
        row.after(note.diff_discussion_html);
        row.next().find(".note").remove();
        discussionContainer = $(".notes[data-discussion-id='" + note.discussion_id + "']");
        discussionContainer.append(note_html);
        if ($('body').attr('data-page').indexOf('projects:merge_request') === 0) {
          $('ul.main-notes-list').append(note.discussion_html).syntaxHighlight();
        }
      } else {
        discussionContainer.append(note_html);
      }

      if ($('resolve-btn, resolve-all-btn').length && (typeof DiffNotesApp !== "undefined" && DiffNotesApp !== null)) {
        $('resolve-btn, resolve-all-btn').each(function () {
          DiffNotesApp.$compile($(this).get(0))
        });
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
      form.find(".js-errors").remove();
      form.find(".js-md-write-button").click();
      form.find(".js-note-text").val("").trigger("input");
      form.find(".js-note-text").data("autosave").reset();
      return this.updateTargetButtons(e);
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
      form = $(".js-new-note-form");
      this.formClone = form.clone();
      this.setupNoteForm(form);
      form.removeClass("js-new-note-form");
      form.addClass("js-main-target-form");
      form.find("#note_line_code").remove();
      form.find("#note_position").remove();
      form.find("#note_type").remove();
      form.find('.js-comment-resolve-button').remove();
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
      this.renderDiscussionNote(note);
      this.removeDiscussionNoteForm($form);

      if ($form.attr('data-resolve-all') != null) {
        var namespace = $form.attr('data-namespace'),
            discussionId = $form.attr('data-discussion-id');

        if (ResolveService != null) {
          ResolveService.resolveAll(namespace, discussionId, false)
        }
      }
    };


    /*
    Called in response to the edit note form being submitted

    Updates the current note field.
     */

    Notes.prototype.updateNote = function(_xhr, note, _status) {
      var $html, $note_li;
      $html = $(note.html);
      gl.utils.localTimeAgo($('.js-timeago', $html));
      $html.syntaxHighlight();
      $html.find('.js-task-list-container').taskList('enable');
      $note_li = $('.note-row-' + note.id);
      return $note_li.replaceWith($html);
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
      note.find(".js-note-attachment-delete").show();
      done = function($noteText) {
        var noteTextVal;
        noteTextVal = $noteText.val();
        form.find('form.edit-note').data('original-note', noteTextVal);
        return $noteText.val('').val(noteTextVal);
      };
      new GLForm(form);
      if ((scrollTo != null) && (myLastNote != null)) {
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
        return function(i, el) {
          var note, notes;
          note = $(el);
          notes = note.closest(".notes");

          if (DiffNotesApp != null) {
            ref = DiffNotesApp.$refs['' + noteId + ''];

            if (ref) {
              ref.$destroy(true);
            }
          }

          if (notes.find(".note").length === 1) {
            notes.closest(".timeline-entry").remove();
            notes.closest("tr").remove();
          }
          return note.remove();
        };
      })(this));
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
      replyLink
        .closest('.discussion-reply-holder')
        .hide()
        .after(form);
      return this.setupDiscussionNoteForm(replyLink, form);
    };


    /*
    Shows the diff or discussion form and does some setup on it.

    Sets some hidden fields in the form.

    Note: dataHolder must have the "discussionId", "lineCode", "noteableType"
    and "noteableId" data attributes set.
     */

    Notes.prototype.setupDiscussionNoteForm = function(dataHolder, form) {
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
      this.setupNoteForm(form);
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
      targetContent = ".notes_content";
      rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\" colspan=\"2\"></td><td class=\"notes_content\"></td></tr>";
      if (this.isParallelView()) {
        lineType = $link.data("lineType");
        targetContent += "." + lineType;
        rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\"></td><td class=\"notes_content parallel old\"></td><td class=\"notes_line\"></td><td class=\"notes_content parallel new\"></td></tr>";
      }
      if (hasNotes) {
        notesContent = nextRow.find(targetContent);
        if (notesContent.length) {
          replyButton = notesContent.find(".js-discussion-reply-button:visible");
          if (replyButton.length) {
            e.target = replyButton[0];
            $.proxy(this.replyToDiscussionNote, replyButton[0], e).call();
          } else {
            noteForm = notesContent.find(".js-discussion-note-form");
            if (noteForm.length === 0) {
              addForm = true;
            }
          }
        }
      } else {
        row.after(rowCssToAdd);
        addForm = true;
      }
      if (addForm) {
        newForm = this.formClone.clone();
        newForm.appendTo(row.next().find(targetContent));
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
      form
        .prev('.discussion-reply-holder')
        .show();
      if (row.is(".js-temp-notes-holder")) {
        return row.remove();
      } else {
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

    Notes.prototype.resolveDiscussion = function () {
      var $this = $(this),
          discussionId = $this.attr('data-discussion-id');

      $this
        .closest('form')
        .attr('data-discussion-id', discussionId)
        .attr('data-resolve-all', 'true')
        .attr('data-namespace', $this.attr('data-namespace'));
    };

    return Notes;

  })();

}).call(this);
