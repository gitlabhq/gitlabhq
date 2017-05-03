/* eslint-disable no-restricted-properties, func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-use-before-define, camelcase, no-unused-expressions, quotes, max-len, one-var, one-var-declaration-per-line, default-case, prefer-template, consistent-return, no-alert, no-return-assign, no-param-reassign, prefer-arrow-callback, no-else-return, comma-dangle, no-new, brace-style, no-lonely-if, vars-on-top, no-unused-vars, no-sequences, no-shadow, newline-per-chained-call, no-useless-escape */
/* global Flash */
/* global Autosave */
/* global ResolveService */
/* global mrRefreshWidgetUrl */

import Cookies from 'js-cookie';
import CommentTypeToggle from './comment_type_toggle';

require('./autosave');
window.autosize = require('vendor/autosize');
window.Dropzone = require('dropzone');
require('./dropzone_input');
require('vendor/jquery.caret'); // required by jquery.atwho
require('vendor/jquery.atwho');
require('./task_list');

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

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
      this.noteable_url = document.URL;
      this.notesCountBadge || (this.notesCountBadge = $(".issuable-details").find(".notes-tab .badge"));
      this.basePollingInterval = 15000;
      this.maxPollingSteps = 4;
      this.cleanBinding();
      this.addBinding();
      this.setPollingInterval();
      this.setupMainTargetNoteForm();
      this.taskList = new gl.TaskList({
        dataType: 'note',
        fieldName: 'note',
        selector: '.notes'
      });
      this.collapseLongCommitList();
      this.setViewType(view);

      // We are in the Merge Requests page so we need another edit form for Changes tab
      if (gl.utils.getPagePath(1) === 'merge_requests') {
        $('.note-edit-form').clone()
          .addClass('mr-note-edit-form').insertAfter('.note-edit-form');
      }
    }

    Notes.prototype.setViewType = function(view) {
      this.view = Cookies.get('diff_view') || view;
    };

    Notes.prototype.addBinding = function() {
      // add note to UI after creation
      $(document).on("ajax:success", ".js-main-target-form", this.addNote);
      $(document).on("ajax:success", ".js-discussion-note-form", this.addDiscussionNote);
      // catch note ajax errors
      $(document).on("ajax:error", ".js-main-target-form", this.addNoteError);
      // change note in UI after update
      $(document).on("ajax:success", "form.edit-note", this.updateNote);
      // Edit note link
      $(document).on("click", ".js-note-edit", this.showEditForm.bind(this));
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
    };

    Notes.initCommentTypeToggle = function (form) {
      const dropdownTrigger = form.querySelector('.js-comment-type-dropdown .dropdown-toggle');
      const dropdownList = form.querySelector('.js-comment-type-dropdown .dropdown-menu');
      const noteTypeInput = form.querySelector('#note_type');
      const submitButton = form.querySelector('.js-comment-type-dropdown .js-comment-submit-button');
      const closeButton = form.querySelector('.js-note-target-close');
      const reopenButton = form.querySelector('.js-note-target-reopen');

      const commentTypeToggle = new CommentTypeToggle({
        dropdownTrigger,
        dropdownList,
        noteTypeInput,
        submitButton,
        closeButton,
        reopenButton,
      });

      commentTypeToggle.initDroplab();
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
      if (!document.hidden) {
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
        headers: { "X-Last-Fetched-At": this.last_fetched_at },
        dataType: "json",
        success: (function(_this) {
          return function(data) {
            var notes;
            notes = data.notes;
            _this.last_fetched_at = data.last_fetched_at;
            _this.setPollingInterval(data.notes.length);
            return $.each(notes, function(i, note) {
              _this.renderNote(note);
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

    Notes.prototype.handleCreateChanges = function(note) {
      var votesBlock;
      if (typeof note === 'undefined') {
        return;
      }

      if (note.commands_changes) {
        if ('merge' in note.commands_changes) {
          $.get(mrRefreshWidgetUrl);
        }

        if ('emoji_award' in note.commands_changes) {
          votesBlock = $('.js-awards-block').eq(0);
          gl.awardsHandler.addAwardToEmojiBar(votesBlock, note.commands_changes.emoji_award);
          return gl.awardsHandler.scrollToAwards();
        }
      }
    };

    /*
    Render note in main comments area.

    Note: for rendering inline notes use renderDiscussionNote
     */

    Notes.prototype.renderNote = function(note, $form) {
      var $notesList;
      if (note.discussion_html != null) {
        return this.renderDiscussionNote(note, $form);
      }

      if (!note.valid) {
        if (note.errors.commands_only) {
          new Flash(note.errors.commands_only, 'notice', this.parentTimeline);
          this.refresh();
        }
        return;
      }

      if (this.isNewNote(note)) {
        this.note_ids.push(note.id);

        $notesList = window.$('ul.main-notes-list');
        Notes.animateAppendNote(note.html, $notesList);

        // Update datetime format on the recent note
        gl.utils.localTimeAgo($notesList.find("#note_" + note.id + " .js-timeago"), false);
        this.collapseLongCommitList();
        this.taskList.init();
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
      return Cookies.get('diff_view') === 'parallel';
    };

    /*
    Render note in discussion area.

    Note: for rendering inline notes use renderDiscussionNote
     */

    Notes.prototype.renderDiscussionNote = function(note, $form) {
      var discussionContainer, form, row, lineType, diffAvatarContainer;
      if (!this.isNewNote(note)) {
        return;
      }
      this.note_ids.push(note.id);
      form = $form || $(".js-discussion-note-form[data-discussion-id='" + note.discussion_id + "']");
      row = form.closest("tr");
      lineType = this.isParallelView() ? form.find('#line_type').val() : 'old';
      diffAvatarContainer = row.prevAll('.line_holder').first().find('.js-avatar-container.' + lineType + '_line');
      // is this the first note of discussion?
      discussionContainer = window.$(`.notes[data-discussion-id="${note.discussion_id}"]`);
      if (!discussionContainer.length) {
        discussionContainer = form.closest('.discussion').find('.notes');
      }
      if (discussionContainer.length === 0) {
        if (note.diff_discussion_html) {
          var $discussion = $(note.diff_discussion_html).renderGFM();

          if (!this.isParallelView() || row.hasClass('js-temp-notes-holder')) {
            // insert the note and the reply button after the temp row
            row.after($discussion);
          } else {
            // Merge new discussion HTML in
            var $notes = $discussion.find('.notes[data-discussion-id="' + note.discussion_id + '"]');
            var contentContainerClass = '.' + $notes.closest('.notes_content')
              .attr('class')
              .split(' ')
              .join('.');

            row.find(contentContainerClass + ' .content').append($notes.closest('.content').children());
          }
        }
        // Init discussion on 'Discussion' page if it is merge request page
        if (window.$('body').attr('data-page').indexOf('projects:merge_request') === 0 || !note.diff_discussion_html) {
          Notes.animateAppendNote(note.discussion_html, window.$('ul.main-notes-list'));
        }
      } else {
        // append new note to all matching discussions
        Notes.animateAppendNote(note.html, discussionContainer);
      }

      if (typeof gl.diffNotesCompileComponents !== 'undefined' && note.discussion_resolvable) {
        gl.diffNotesCompileComponents();
        this.renderDiscussionAvatar(diffAvatarContainer, note);
      }

      gl.utils.localTimeAgo($('.js-timeago'), false);
      return this.updateNotesCount(1);
    };

    Notes.prototype.getLineHolder = function(changesDiscussionContainer) {
      return $(changesDiscussionContainer).closest('.notes_holder')
        .prevAll('.line_holder')
        .first()
        .get(0);
    };

    Notes.prototype.renderDiscussionAvatar = function(diffAvatarContainer, note) {
      var commentButton = diffAvatarContainer.find('.js-add-diff-note-button');
      var avatarHolder = diffAvatarContainer.find('.diff-comment-avatar-holders');

      if (!avatarHolder.length) {
        avatarHolder = document.createElement('diff-note-avatars');
        avatarHolder.setAttribute('discussion-id', note.discussion_id);

        diffAvatarContainer.append(avatarHolder);

        gl.diffNotesCompileComponents();
      }

      if (commentButton.length) {
        commentButton.remove();
      }
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
      form.find("#note_type").val('');
      form.find("#in_reply_to_discussion_id").remove();
      form.find('.js-comment-resolve-button').closest('comment-and-resolve-btn').remove();
      this.parentTimeline = form.parents('.timeline');

      if (form.length) {
        Notes.initCommentTypeToggle(form.get(0));
      }
    };

    /*
    General note form setup.

    deactivates the submit button when text is empty
    hides the preview button when text is empty
    setup GFM auto complete
    show the form
     */

    Notes.prototype.setupNoteForm = function(form) {
      var textarea, key;
      new gl.GLForm(form);
      textarea = form.find(".js-note-text");
      key = [
        "Note",
        form.find("#note_noteable_type").val(),
        form.find("#note_noteable_id").val(),
        form.find("#note_commit_id").val(),
        form.find("#note_type").val(),
        form.find("#in_reply_to_discussion_id").val(),

        // LegacyDiffNote
        form.find("#note_line_code").val(),

        // DiffNote
        form.find("#note_position").val()
      ];
      return new Autosave(textarea, key);
    };

    /*
    Called in response to the new note form being submitted

    Adds new note to list.
     */

    Notes.prototype.addNote = function(xhr, note, status) {
      this.handleCreateChanges(note);
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
          ResolveService.toggleResolveForDiscussion(mergeRequestId, discussionId);
        }
      }

      this.renderNote(note, $form);
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
      this.revertNoteEditForm();
      gl.utils.localTimeAgo($('.js-timeago', $html));
      $html.renderGFM();
      $html.find('.js-task-list-container').taskList('enable');
      // Find the note's `li` element by ID and replace it with the updated HTML
      $note_li = $('.note-row-' + note.id);

      $note_li.replaceWith($html);

      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        gl.diffNotesCompileComponents();
      }
    };

    Notes.prototype.checkContentToAllowEditing = function($el) {
      var initialContent = $el.find('.original-note-content').text().trim();
      var currentContent = $el.find('.note-textarea').val();
      var isAllowed = true;

      if (currentContent === initialContent) {
        this.removeNoteEditForm($el);
      }
      else {
        var $buttons = $el.find('.note-form-actions');
        var isWidgetVisible = gl.utils.isInViewport($el.get(0));

        if (!isWidgetVisible) {
          gl.utils.scrollToElement($el);
        }

        $el.find('.js-edit-warning').show();
        isAllowed = false;
      }

      return isAllowed;
    };

    /*
    Called in response to clicking the edit note link

    Replaces the note text with the note edit form
    Adds a data attribute to the form with the original content of the note for cancellations
    */
    Notes.prototype.showEditForm = function(e, scrollTo, myLastNote) {
      e.preventDefault();

      var $target = $(e.target);
      var $editForm = $(this.getEditFormSelector($target));
      var $note = $target.closest('.note');
      var $currentlyEditing = $('.note.is-editting:visible');

      if ($currentlyEditing.length) {
        var isEditAllowed = this.checkContentToAllowEditing($currentlyEditing);

        if (!isEditAllowed) {
          return;
        }
      }

      $note.find('.js-note-attachment-delete').show();
      $editForm.addClass('current-note-edit-form');
      $note.addClass('is-editting');
      this.putEditFormInPlace($target);
    };

    /*
    Called in response to clicking the edit note link

    Hides edit form and restores the original note text to the editor textarea.
     */

    Notes.prototype.cancelEdit = function(e) {
      e.preventDefault();
      var $target = $(e.target);
      var note = $target.closest('.note');
      note.find('.js-edit-warning').hide();
      this.revertNoteEditForm($target);
      return this.removeNoteEditForm(note);
    };

    Notes.prototype.revertNoteEditForm = function($target) {
      $target = $target || $('.note.is-editting:visible');
      var selector = this.getEditFormSelector($target);
      var $editForm = $(selector);

      $editForm.insertBefore('.notes-form');
      $editForm.find('.js-comment-button').enable();
      $editForm.find('.js-edit-warning').hide();
    };

    Notes.prototype.getEditFormSelector = function($el) {
      var selector = '.note-edit-form:not(.mr-note-edit-form)';

      if ($el.parents('#diffs').length) {
        selector = '.note-edit-form.mr-note-edit-form';
      }

      return selector;
    };

    Notes.prototype.removeNoteEditForm = function(note) {
      var form = note.find('.current-note-edit-form');
      note.removeClass('is-editting');
      form.removeClass('current-note-edit-form');
      form.find('.js-edit-warning').hide();
      // Replace markdown textarea text with original note text.
      return form.find('.js-note-text').val(form.find('form.edit-note').data('original-note'));
    };

    /*
    Called in response to deleting a note of any kind.

    Removes the actual note from view.
    Removes the whole discussion if the last note is being removed.
     */

    Notes.prototype.removeNote = function(e) {
      var noteElId, noteId, dataNoteId, $note, lineHolder;
      $note = $(e.currentTarget).closest('.note');
      noteElId = $note.attr('id');
      noteId = $note.attr('data-note-id');
      lineHolder = $(e.currentTarget).closest('.notes[data-discussion-id]')
        .closest('.notes_holder')
        .prev('.line_holder');
      $(".note[id='" + noteElId + "']").each((function(_this) {
        // A same note appears in the "Discussion" and in the "Changes" tab, we have
        // to remove all. Using $(".note[id='noteId']") ensure we get all the notes,
        // where $("#noteId") would return only one.
        return function(i, el) {
          var note, notes;
          note = $(el);
          notes = note.closest(".discussion-notes");

          if (typeof gl.diffNotesCompileComponents !== 'undefined') {
            if (gl.diffNoteApps[noteElId]) {
              gl.diffNoteApps[noteElId].$destroy();
            }
          }

          note.remove();

          // check if this is the last note for this line
          if (notes.find(".note").length === 0) {
            var notesTr = notes.closest("tr");

            // "Discussions" tab
            notes.closest(".timeline-entry").remove();

            // The notes tr can contain multiple lists of notes, like on the parallel diff
            if (notesTr.find('.discussion-notes').length > 1) {
              notes.remove();
            } else {
              notesTr.remove();
            }
          }
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
      form = this.cleanForm(this.formClone.clone());
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

    Note: dataHolder must have the "discussionId" and "lineCode" data attributes set.
     */

    Notes.prototype.setupDiscussionNoteForm = function(dataHolder, form) {
      // setup note target
      var discussionID = dataHolder.data("discussionId");

      if (discussionID) {
        form.attr("data-discussion-id", discussionID);
        form.find("#in_reply_to_discussion_id").val(discussionID);
      }

      form.attr("data-line-code", dataHolder.data("lineCode"));
      form.find("#line_type").val(dataHolder.data("lineType"));

      form.find("#note_noteable_type").val(dataHolder.data("noteableType"));
      form.find("#note_noteable_id").val(dataHolder.data("noteableId"));
      form.find("#note_commit_id").val(dataHolder.data("commitId"));
      form.find("#note_type").val(dataHolder.data("noteType"));

      // LegacyDiffNote
      form.find("#note_line_code").val(dataHolder.data("lineCode"));

      // DiffNote
      form.find("#note_position").val(dataHolder.attr("data-position"));

      form.find('.js-note-discard').show().removeClass('js-note-discard').addClass('js-close-discussion-note-form').text(form.find('.js-close-discussion-note-form').data('cancel-text'));
      form.find('.js-note-target-close').remove();
      form.find('.js-note-new-discussion').remove();
      this.setupNoteForm(form);

      form
        .removeClass('js-main-target-form')
        .addClass("discussion-form js-discussion-note-form");

      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        var $commentBtn = form.find('comment-and-resolve-btn');
        $commentBtn.attr(':discussion-id', `'${discussionID}'`);

        gl.diffNotesCompileComponents();
      }

      form.find(".js-note-text").focus();
      form
        .find('.js-comment-resolve-button')
        .attr('data-discussion-id', discussionID);
    };

    /*
    Called when clicking on the "add a comment" button on the side of a diff line.

    Inserts a temporary row for the form below the line.
    Sets up the form and shows it.
     */

    Notes.prototype.addDiffNote = function(e) {
      var $link, addForm, hasNotes, lineType, newForm, nextRow, noteForm, notesContent, notesContentSelector, replyButton, row, rowCssToAdd, targetContent, isDiffCommentAvatar;
      e.preventDefault();
      $link = $(e.currentTarget || e.target);
      row = $link.closest("tr");
      nextRow = row.next();
      hasNotes = nextRow.is(".notes_holder");
      addForm = false;
      notesContentSelector = ".notes_content";
      rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\" colspan=\"2\"></td><td class=\"notes_content\"><div class=\"content\"></div></td></tr>";
      isDiffCommentAvatar = $link.hasClass('js-diff-comment-avatar');
      // In parallel view, look inside the correct left/right pane
      if (this.isParallelView()) {
        lineType = $link.data("lineType");
        notesContentSelector += "." + lineType;
        rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line old\"></td><td class=\"notes_content parallel old\"><div class=\"content\"></div></td><td class=\"notes_line new\"></td><td class=\"notes_content parallel new\"><div class=\"content\"></div></td></tr>";
      }
      notesContentSelector += " .content";
      notesContent = nextRow.find(notesContentSelector);

      if (hasNotes && !isDiffCommentAvatar) {
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
      } else if (!isDiffCommentAvatar) {
        // add a notes row and insert the form
        row.after(rowCssToAdd);
        nextRow = row.next();
        notesContent = nextRow.find(notesContentSelector);
        addForm = true;
      } else {
        nextRow.show();
        notesContent.toggle(!notesContent.is(':visible'));

        if (!nextRow.find('.content:not(:empty)').is(':visible')) {
          nextRow.hide();
        }
      }

      if (addForm) {
        newForm = this.cleanForm(this.formClone.clone());
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
        reopentext = reopenbtn.attr('data-alternative-text');
        closetext = closebtn.attr('data-alternative-text');
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

    Notes.prototype.putEditFormInPlace = function($el) {
      var $editForm = $(this.getEditFormSelector($el));
      var $note = $el.closest('.note');

      $editForm.insertAfter($note.find('.note-text'));

      var $originalContentEl = $note.find('.original-note-content');
      var originalContent = $originalContentEl.text().trim();
      var postUrl = $originalContentEl.data('post-url');
      var targetId = $originalContentEl.data('target-id');
      var targetType = $originalContentEl.data('target-type');

      new gl.GLForm($editForm.find('form'));

      $editForm.find('form')
        .attr('action', postUrl)
        .attr('data-remote', 'true');
      $editForm.find('.js-form-target-id').val(targetId);
      $editForm.find('.js-form-target-type').val(targetType);
      $editForm.find('.js-note-text').focus().val(originalContent);
      $editForm.find('.js-md-write-button').trigger('click');
      $editForm.find('.referenced-users').hide();
    };

    Notes.prototype.updateNotesCount = function(updateCount) {
      return this.notesCountBadge.text(parseInt(this.notesCountBadge.text(), 10) + updateCount);
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
      const $element = $(e.currentTarget);
      const $closestSystemCommitList = $element.siblings('.system-note-commit-list');

      $element.find('.fa').toggleClass('fa-angle-down').toggleClass('fa-angle-up');
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

    Notes.prototype.cleanForm = function($form) {
      // Remove JS classes that are not needed here
      $form
        .find('.js-comment-type-dropdown')
        .removeClass('btn-group');

      // Remove dropdown
      $form
        .find('.dropdown-menu')
        .remove();

      return $form;
    };

    Notes.animateAppendNote = function(noteHTML, $notesList) {
      const $note = window.$(noteHTML);

      $note.addClass('fade-in').renderGFM();
      $notesList.append($note);
    };

    return Notes;
  })();
}).call(window);
