/* eslint-disable no-restricted-properties, babel/camelcase,
no-unused-expressions, default-case,
consistent-return, no-alert, no-param-reassign,
no-shadow, no-useless-escape,
class-methods-use-this */

/* global ResolveService */

/*
old_notes_spec.js is the spec for the legacy, jQuery notes application. It has nothing to do with the new, fancy Vue notes app.
 */

import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import Autosize from 'autosize';
import $ from 'jquery';
import Cookies from 'js-cookie';
import { escape, uniqueId } from 'lodash';
import Vue from 'vue';
import '~/lib/utils/jquery_at_who';
import AjaxCache from '~/lib/utils/ajax_cache';
import syntaxHighlight from '~/syntax_highlight';
import Autosave from './autosave';
import loadAwardsHandler from './awards_handler';
import CommentTypeToggle from './comment_type_toggle';
import createFlash from './flash';
import { defaultAutocompleteConfig } from './gfm_auto_complete';
import GLForm from './gl_form';
import axios from './lib/utils/axios_utils';
import {
  isInViewport,
  getPagePath,
  scrollToElement,
  isMetaKey,
  isInMRPage,
} from './lib/utils/common_utils';
import { localTimeAgo } from './lib/utils/datetime_utility';
import { getLocationHash } from './lib/utils/url_utility';
import { sprintf, s__, __ } from './locale';
import TaskList from './task_list';

window.autosize = Autosize;

function normalizeNewlines(str) {
  return str.replace(/\r\n/g, '\n');
}

const MAX_VISIBLE_COMMIT_LIST_COUNT = 3;
const REGEX_QUICK_ACTIONS = /^\/\w+.*$/gm;

export default class Notes {
  static initialize(notes_url, note_ids, last_fetched_at, view, enableGFM) {
    if (!this.instance) {
      this.instance = new Notes(notes_url, note_ids, last_fetched_at, view, enableGFM);
    }
  }

  static getInstance() {
    return this.instance;
  }

  constructor(notes_url, note_ids, last_fetched_at, view, enableGFM = defaultAutocompleteConfig) {
    this.updateTargetButtons = this.updateTargetButtons.bind(this);
    this.updateComment = this.updateComment.bind(this);
    this.visibilityChange = this.visibilityChange.bind(this);
    this.cancelDiscussionForm = this.cancelDiscussionForm.bind(this);
    this.onAddDiffNote = this.onAddDiffNote.bind(this);
    this.onAddImageDiffNote = this.onAddImageDiffNote.bind(this);
    this.setupDiscussionNoteForm = this.setupDiscussionNoteForm.bind(this);
    this.onReplyToDiscussionNote = this.onReplyToDiscussionNote.bind(this);
    this.removeNote = this.removeNote.bind(this);
    this.cancelEdit = this.cancelEdit.bind(this);
    this.updateNote = this.updateNote.bind(this);
    this.addDiscussionNote = this.addDiscussionNote.bind(this);
    this.addNoteError = this.addNoteError.bind(this);
    this.addNote = this.addNote.bind(this);
    this.resetMainTargetForm = this.resetMainTargetForm.bind(this);
    this.refresh = this.refresh.bind(this);
    this.keydownNoteText = this.keydownNoteText.bind(this);
    this.toggleCommitList = this.toggleCommitList.bind(this);
    this.postComment = this.postComment.bind(this);
    this.clearFlashWrapper = this.clearFlash.bind(this);
    this.onHashChange = this.onHashChange.bind(this);

    this.notes_url = notes_url;
    this.note_ids = note_ids;
    this.enableGFM = enableGFM;
    // Used to keep track of updated notes while people are editing things
    this.updatedNotesTrackingMap = {};
    this.last_fetched_at = last_fetched_at;
    this.noteable_url = document.URL;
    this.notesCountBadge ||
      (this.notesCountBadge = $('.issuable-details').find('.notes-tab .badge'));
    this.basePollingInterval = 15000;
    this.maxPollingSteps = 4;

    this.$wrapperEl = isInMRPage() ? $(document).find('.diffs') : $(document);
    this.cleanBinding();
    this.addBinding();
    this.setPollingInterval();
    this.setupMainTargetNoteForm(enableGFM);
    this.taskList = new TaskList({
      dataType: 'note',
      fieldName: 'note',
      selector: '.notes',
    });
    this.collapseLongCommitList();
    this.setViewType(view);

    // We are in the merge requests page so we need another edit form for Changes tab
    if (getPagePath(1) === 'merge_requests') {
      $('.note-edit-form').clone().addClass('mr-note-edit-form').insertAfter('.note-edit-form');
    }

    const hash = getLocationHash();
    const $anchor = hash && document.getElementById(hash);

    if ($anchor) {
      this.loadLazyDiff({ currentTarget: $anchor });
    }
  }

  setViewType(view) {
    this.view = Cookies.get('diff_view') || view;
  }

  addBinding() {
    // Edit note link
    this.$wrapperEl.on('click', '.js-note-edit', this.showEditForm.bind(this));
    this.$wrapperEl.on('click', '.note-edit-cancel', this.cancelEdit);
    // Reopen and close actions for Issue/MR combined with note form submit
    this.$wrapperEl.on('click', '.js-comment-submit-button', this.postComment);
    this.$wrapperEl.on('click', '.js-comment-save-button', this.updateComment);
    this.$wrapperEl.on('keyup input', '.js-note-text', this.updateTargetButtons);
    // resolve a discussion
    this.$wrapperEl.on('click', '.js-comment-resolve-button', this.postComment);
    // remove a note (in general)
    this.$wrapperEl.on('click', '.js-note-delete', this.removeNote);
    // delete note attachment
    this.$wrapperEl.on('click', '.js-note-attachment-delete', this.removeAttachment);
    // update the file name when an attachment is selected
    this.$wrapperEl.on('change', '.js-note-attachment-input', this.updateFormAttachment);
    // reply to diff/discussion notes
    this.$wrapperEl.on('click', '.js-discussion-reply-button', this.onReplyToDiscussionNote);
    // add diff note
    this.$wrapperEl.on('click', '.js-add-diff-note-button', this.onAddDiffNote);
    // add diff note for images
    this.$wrapperEl.on('click', '.js-add-image-diff-note-button', this.onAddImageDiffNote);
    // hide diff note form
    this.$wrapperEl.on('click', '.js-close-discussion-note-form', this.cancelDiscussionForm);
    // toggle commit list
    this.$wrapperEl.on('click', '.system-note-commit-list-toggler', this.toggleCommitList);

    this.$wrapperEl.on('click', '.js-toggle-lazy-diff', this.loadLazyDiff);
    this.$wrapperEl.on(
      'click',
      '.js-toggle-lazy-diff-retry-button',
      this.onClickRetryLazyLoad.bind(this),
    );

    // fetch notes when tab becomes visible
    this.$wrapperEl.on('visibilitychange', this.visibilityChange);
    // when issue status changes, we need to refresh data
    this.$wrapperEl.on('issuable:change', this.refresh);
    // ajax:events that happen on Form when actions like Reopen, Close are performed on Issues and MRs.
    this.$wrapperEl.on('ajax:success', '.js-main-target-form', this.addNote);
    this.$wrapperEl.on('ajax:success', '.js-discussion-note-form', this.addDiscussionNote);
    this.$wrapperEl.on('ajax:success', '.js-main-target-form', this.resetMainTargetForm);
    this.$wrapperEl.on(
      'ajax:complete',
      '.js-main-target-form',
      this.reenableTargetFormSubmitButton,
    );
    // when a key is clicked on the notes
    this.$wrapperEl.on('keydown', '.js-note-text', this.keydownNoteText);
    // When the URL fragment/hash has changed, `#note_xxx`
    $(window).on('hashchange', this.onHashChange);
  }

  cleanBinding() {
    this.$wrapperEl.off('click', '.js-note-edit');
    this.$wrapperEl.off('click', '.note-edit-cancel');
    this.$wrapperEl.off('click', '.js-note-delete');
    this.$wrapperEl.off('click', '.js-note-attachment-delete');
    this.$wrapperEl.off('click', '.js-discussion-reply-button');
    this.$wrapperEl.off('click', '.js-add-diff-note-button');
    this.$wrapperEl.off('click', '.js-add-image-diff-note-button');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$wrapperEl.off('visibilitychange');
    this.$wrapperEl.off('keyup input', '.js-note-text');
    this.$wrapperEl.off('click', '.js-note-target-reopen');
    this.$wrapperEl.off('click', '.js-note-target-close');
    this.$wrapperEl.off('keydown', '.js-note-text');
    this.$wrapperEl.off('click', '.js-comment-resolve-button');
    this.$wrapperEl.off('click', '.system-note-commit-list-toggler');
    this.$wrapperEl.off('click', '.js-toggle-lazy-diff');
    this.$wrapperEl.off('click', '.js-toggle-lazy-diff-retry-button');
    this.$wrapperEl.off('ajax:success', '.js-main-target-form');
    this.$wrapperEl.off('ajax:success', '.js-discussion-note-form');
    this.$wrapperEl.off('ajax:complete', '.js-main-target-form');
    $(window).off('hashchange', this.onHashChange);
  }

  static initCommentTypeToggle(form) {
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
  }

  keydownNoteText(e) {
    let discussionNoteForm;
    let editNote;
    let myLastNote;
    let myLastNoteEditBtn;
    let newText;
    let originalText;

    if (isMetaKey(e)) {
      return;
    }

    const $textarea = $(e.target);
    // Edit previous note when UP arrow is hit
    switch (e.which) {
      case 38:
        if ($textarea.val() !== '') {
          return;
        }
        myLastNote = $(
          `li.note[data-author-id='${gon.current_user_id}'][data-editable]:last`,
          $textarea.closest('.note, .notes_holder, #notes'),
        );
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
            if (!window.confirm(__('Your comment will be discarded.'))) {
              return;
            }
          }
          this.removeDiscussionNoteForm(discussionNoteForm);
          return;
        }
        editNote = $textarea.closest('.note');
        if (editNote.length) {
          originalText = $textarea.closest('form').data('originalNote');
          newText = $textarea.val();
          if (originalText !== newText) {
            if (!window.confirm(__('Are you sure you want to discard this comment?'))) {
              return;
            }
          }
          return this.removeNoteEditForm(editNote);
        }
    }
  }

  initRefresh() {
    if (Notes.interval) {
      clearInterval(Notes.interval);
    }
    Notes.interval = setInterval(() => this.refresh(), this.pollingInterval);
  }

  refresh() {
    if (!document.hidden) {
      return this.getContent();
    }
  }

  getContent() {
    if (this.refreshing) {
      return;
    }

    this.refreshing = true;

    axios
      .get(`${this.notes_url}?html=true`, {
        headers: {
          'X-Last-Fetched-At': this.last_fetched_at,
        },
      })
      .then(({ data }) => {
        const { notes } = data;
        this.last_fetched_at = data.last_fetched_at;
        this.setPollingInterval(data.notes.length);
        $.each(notes, (i, note) => this.renderNote(note));

        this.refreshing = false;
      })
      .catch(() => {
        this.refreshing = false;
      });
  }

  /**
   * Increase @pollingInterval up to 120 seconds on every function call,
   * if `shouldReset` has a truthy value, 'null' or 'undefined' the variable
   * will reset to @basePollingInterval.
   *
   * Note: this function is used to gradually increase the polling interval
   * if there aren't new notes coming from the server
   */
  setPollingInterval(shouldReset) {
    if (shouldReset == null) {
      shouldReset = true;
    }
    const nthInterval = this.basePollingInterval * Math.pow(2, this.maxPollingSteps - 1);
    if (shouldReset) {
      this.pollingInterval = this.basePollingInterval;
    } else if (this.pollingInterval < nthInterval) {
      this.pollingInterval *= 2;
    }
    return this.initRefresh();
  }

  handleQuickActions(noteEntity) {
    let votesBlock;
    if (noteEntity.commands_changes) {
      if ('merge' in noteEntity.commands_changes) {
        Notes.checkMergeRequestStatus();
      }

      if ('emoji_award' in noteEntity.commands_changes) {
        votesBlock = $('.js-awards-block').eq(0);

        loadAwardsHandler()
          .then((awardsHandler) => {
            awardsHandler.addAwardToEmojiBar(votesBlock, noteEntity.commands_changes.emoji_award);
            awardsHandler.scrollToAwards();
          })
          .catch(() => {
            // ignore
          });
      }
    }
  }

  setupNewNote($note) {
    // Update datetime format on the recent note
    localTimeAgo($note.find('.js-timeago').get(), false);

    this.collapseLongCommitList();
    this.taskList.init();

    // This stops the note highlight, #note_xxx`, from being removed after real time update
    // The `:target` selector does not re-evaluate after we replace element in the DOM
    Notes.updateNoteTargetSelector($note);
    this.$noteToCleanHighlight = $note;
  }

  onHashChange() {
    if (this.$noteToCleanHighlight) {
      Notes.updateNoteTargetSelector(this.$noteToCleanHighlight);
    }

    this.$noteToCleanHighlight = null;
  }

  static updateNoteTargetSelector($note) {
    const hash = getLocationHash();
    // Needs to be an explicit true/false for the jQuery `toggleClass(force)`
    const addTargetClass = Boolean(hash && $note.filter(`#${hash}`).length > 0);
    $note.toggleClass('target', addTargetClass);
  }

  /**
   * Render note in main comments area.
   *
   * Note: for rendering inline notes use renderDiscussionNote
   */
  renderNote(noteEntity, $form, $notesList = $('.main-notes-list')) {
    if (noteEntity.discussion_html) {
      return this.renderDiscussionNote(noteEntity, $form);
    }

    if (!noteEntity.valid) {
      if (noteEntity.errors && noteEntity.errors.commands_only) {
        if (noteEntity.commands_changes && Object.keys(noteEntity.commands_changes).length > 0) {
          $notesList.find('.system-note.being-posted').remove();
        }
        this.addFlash({
          message: noteEntity.errors.commands_only,
          type: 'notice',
          parent: this.parentTimeline.get(0),
        });
        this.refresh();
      }
      return;
    }

    const $note = $notesList.find(`#note_${noteEntity.id}`);
    if (Notes.isNewNote(noteEntity, this.note_ids)) {
      if (isInMRPage()) {
        return;
      }

      this.note_ids.push(noteEntity.id);

      if ($notesList.length) {
        $notesList.find('.system-note.being-posted').remove();
      }
      const $newNote = Notes.animateAppendNote(noteEntity.html, $notesList);

      this.setupNewNote($newNote);
      this.refresh();
      return this.updateNotesCount(1);
    } else if (Notes.isUpdatedNote(noteEntity, $note)) {
      // The server can send the same update multiple times so we need to make sure to only update once per actual update.
      const isEditing = $note.hasClass('is-editing');
      const initialContent = normalizeNewlines($note.find('.original-note-content').text().trim());
      const $textarea = $note.find('.js-note-text');
      const currentContent = $textarea.val();
      // There can be CRLF vs LF mismatches if we don't sanitize and compare the same way
      const sanitizedNoteNote = normalizeNewlines(noteEntity.note);
      const isTextareaUntouched =
        currentContent === initialContent || currentContent === sanitizedNoteNote;

      if (isEditing && isTextareaUntouched) {
        $textarea.val(noteEntity.note);
        this.updatedNotesTrackingMap[noteEntity.id] = noteEntity;
      } else if (isEditing && !isTextareaUntouched) {
        this.putConflictEditWarningInPlace(noteEntity, $note);
        this.updatedNotesTrackingMap[noteEntity.id] = noteEntity;
      } else {
        const $updatedNote = Notes.animateUpdateNote(noteEntity.html, $note);
        this.setupNewNote($updatedNote);
      }
    }
  }

  isParallelView() {
    return Cookies.get('diff_view') === 'parallel';
  }

  /**
   * Render note in discussion area. To render inline notes use renderDiscussionNote.
   */
  renderDiscussionNote(noteEntity, $form) {
    let discussionContainer;
    let row;

    if (!Notes.isNewNote(noteEntity, this.note_ids)) {
      return;
    }
    this.note_ids.push(noteEntity.id);

    const form =
      $form || $(`.js-discussion-note-form[data-discussion-id="${noteEntity.discussion_id}"]`);
    row =
      form.length || !noteEntity.discussion_line_code
        ? form.closest('tr')
        : $(`#${noteEntity.discussion_line_code}`);

    if (noteEntity.on_image) {
      row = form;
    }

    // is this the first note of discussion?
    discussionContainer = $(`.notes[data-discussion-id="${noteEntity.discussion_id}"]`);
    if (!discussionContainer.length) {
      discussionContainer = form.closest('.discussion').find('.notes');
    }
    if (discussionContainer.length === 0) {
      if (noteEntity.diff_discussion_html) {
        const $discussion = $(noteEntity.diff_discussion_html).renderGFM();

        if (!this.isParallelView() || row.hasClass('js-temp-notes-holder') || noteEntity.on_image) {
          // insert the note and the reply button after the temp row
          row.after($discussion);
        } else {
          // Merge new discussion HTML in
          const $notes = $discussion.find(
            `.notes[data-discussion-id="${noteEntity.discussion_id}"]`,
          );
          const contentContainerClass = $notes
            .closest('.notes-content')
            .attr('class')
            .split(' ')
            .join('.');

          row
            .find(`.${contentContainerClass} .content`)
            .append($notes.closest('.content').children());
        }
      } else {
        Notes.animateAppendNote(noteEntity.discussion_html, $('.main-notes-list'));
      }
    } else {
      // append new note to all matching discussions
      Notes.animateAppendNote(noteEntity.html, discussionContainer);
    }

    localTimeAgo(document.querySelectorAll('.js-timeago'), false);
    Notes.checkMergeRequestStatus();
    return this.updateNotesCount(1);
  }

  getLineHolder(changesDiscussionContainer) {
    return $(changesDiscussionContainer)
      .closest('.notes_holder')
      .prevAll('.line_holder')
      .first()
      .get(0);
  }

  /**
   * Called in response the main target form has been successfully submitted.
   *
   * Removes any errors.
   * Resets text and preview.
   * Resets buttons.
   */
  resetMainTargetForm(e) {
    const form = $('.js-main-target-form');
    // remove validation errors
    form.find('.js-errors').remove();
    // reset text and preview
    form.find('.js-md-write-button').click();
    form.find('.js-note-text').val('').trigger('input');
    form.find('.js-note-text').data('autosave').reset();

    const event = document.createEvent('Event');
    event.initEvent('autosize:update', true, false);
    form.find('.js-autosize')[0].dispatchEvent(event);

    this.updateTargetButtons(e);
  }

  reenableTargetFormSubmitButton() {
    const form = $('.js-main-target-form');
    return form.find('.js-note-text').trigger('input');
  }

  /**
   * Shows the main form and does some setup on it.
   *
   * Sets some hidden fields in the form.
   */
  setupMainTargetNoteForm(enableGFM) {
    // find the form
    const form = $('.js-new-note-form');
    // Set a global clone of the form for later cloning
    this.formClone = form.clone();
    // show the form
    this.setupNoteForm(form, enableGFM);
    // fix classes
    form.removeClass('js-new-note-form');
    form.addClass('js-main-target-form');
    form.find('#note_line_code').remove();
    form.find('#note_position').remove();
    form.find('#note_type').val('');
    form.find('#note_project_id').remove();
    form.find('#in_reply_to_discussion_id').remove();
    this.parentTimeline = form.parents('.timeline');

    if (form.length) {
      Notes.initCommentTypeToggle(form.get(0));
    }
  }

  /**
   * General note form setup.
   *
   * deactivates the submit button when text is empty
   * hides the preview button when text is empty
   * set up GFM auto complete
   * show the form
   */
  setupNoteForm(form, enableGFM = defaultAutocompleteConfig) {
    this.glForm = new GLForm(form, enableGFM);
    const textarea = form.find('.js-note-text');
    const key = [
      s__('NoteForm|Note'),
      form.find('#note_noteable_type').val(),
      form.find('#note_noteable_id').val(),
      form.find('#note_commit_id').val(),
      form.find('#note_type').val(),
      form.find('#note_project_id').val(),
      form.find('#in_reply_to_discussion_id').val(),

      // LegacyDiffNote
      form.find('#note_line_code').val(),

      // DiffNote
      form.find('#note_position').val(),
    ];
    return new Autosave(textarea, key);
  }

  /**
   * Called in response to the new note form being submitted
   *
   * Adds new note to list.
   */
  addNote($form, note) {
    return this.renderNote(note);
  }

  addNoteError($form) {
    let formParentTimeline;
    if ($form.hasClass('js-main-target-form')) {
      formParentTimeline = $form.parents('.timeline');
    } else if ($form.hasClass('js-discussion-note-form')) {
      formParentTimeline = $form.closest('.discussion-notes').find('.notes');
    }
    return this.addFlash({
      message: __(
        'Your comment could not be submitted! Please check your network connection and try again.',
      ),
      parent: formParentTimeline.get(0),
    });
  }

  updateNoteError() {
    createFlash({
      message: __(
        'Your comment could not be updated! Please check your network connection and try again.',
      ),
    });
  }

  /**
   * Called in response to the new note form being submitted
   *
   * Adds new note to list.
   */
  addDiscussionNote($form, note, isNewDiffComment) {
    if ($form.attr('data-resolve-all') != null) {
      const discussionId = $form.data('discussionId');
      const mergeRequestId = $form.data('noteableIid');

      if (ResolveService != null) {
        ResolveService.toggleResolveForDiscussion(mergeRequestId, discussionId);
      }
    }

    this.renderNote(note, $form);
    // cleanup after successfully creating a diff/discussion note
    if (isNewDiffComment) {
      this.removeDiscussionNoteForm($form);
    }
  }

  /**
   * Called in response to the edit note form being submitted
   *
   * Updates the current note field.
   */
  updateNote(noteEntity, $targetNote) {
    // Convert returned HTML to a jQuery object so we can modify it further
    const $noteEntityEl = $(noteEntity.html);
    this.revertNoteEditForm($targetNote);
    $noteEntityEl.renderGFM();
    // Find the note's `li` element by ID and replace it with the updated HTML
    const $note_li = $(`.note-row-${noteEntity.id}`);

    $note_li.replaceWith($noteEntityEl);
    this.setupNewNote($noteEntityEl);
  }

  checkContentToAllowEditing($el) {
    const initialContent = $el.find('.original-note-content').text().trim();
    const currentContent = $el.find('.js-note-text').val();
    let isAllowed = true;

    if (currentContent === initialContent) {
      this.removeNoteEditForm($el);
    } else {
      const isWidgetVisible = isInViewport($el.get(0));

      if (!isWidgetVisible) {
        scrollToElement($el);
      }

      $el.find('.js-finish-edit-warning').show();
      isAllowed = false;
    }

    return isAllowed;
  }

  /**
   * Called in response to clicking the edit note link
   *
   * Replaces the note text with the note edit form
   * Adds a data attribute to the form with the original content of the note for cancellations
   */
  showEditForm(e) {
    e.preventDefault();

    const $target = $(e.target);
    const $editForm = $(this.getEditFormSelector($target));
    const $note = $target.closest('.note');
    const $currentlyEditing = $('.note.is-editing:visible');

    if ($currentlyEditing.length) {
      const isEditAllowed = this.checkContentToAllowEditing($currentlyEditing);

      if (!isEditAllowed) {
        return;
      }
    }

    $note.find('.js-note-attachment-delete').show();
    $editForm.addClass('current-note-edit-form');
    $note.addClass('is-editing');
    this.putEditFormInPlace($target);
  }

  /**
   * Called in response to clicking the edit note link
   *
   * Hides edit form and restores the original note text to the editor textarea.
   */
  cancelEdit(e) {
    e.preventDefault();
    const $target = $(e.target);
    const $note = $target.closest('.note');
    const noteId = $note.attr('data-note-id');

    this.revertNoteEditForm($target);

    if (this.updatedNotesTrackingMap[noteId]) {
      const $newNote = $(this.updatedNotesTrackingMap[noteId].html);
      $note.replaceWith($newNote);
      this.setupNewNote($newNote);
      // Now that we have taken care of the update, clear it out
      delete this.updatedNotesTrackingMap[noteId];
    } else {
      $note.find('.js-finish-edit-warning').hide();
      this.removeNoteEditForm($note);
    }
  }

  revertNoteEditForm($target) {
    $target = $target || $('.note.is-editing:visible');
    const selector = this.getEditFormSelector($target);
    const $editForm = $(selector);

    $editForm.insertBefore('.diffs');
    $editForm.find('.js-comment-save-button').enable();
    $editForm.find('.js-finish-edit-warning').hide();
  }

  getEditFormSelector($el) {
    let selector = '.note-edit-form:not(.mr-note-edit-form)';

    if ($el.parents('#diffs').length) {
      selector = '.note-edit-form.mr-note-edit-form';
    }

    return selector;
  }

  removeNoteEditForm($note) {
    const form = $note.find('.diffs .current-note-edit-form');

    $note.removeClass('is-editing');
    form.removeClass('current-note-edit-form');
    form.find('.js-finish-edit-warning').hide();
    // Replace markdown textarea text with original note text.
    return form.find('.js-note-text').val(form.find('form.edit-note').data('originalNote'));
  }

  /**
   * Called in response to deleting a note of any kind.
   *
   * Removes the actual note from view.
   * Removes the whole discussion if the last note is being removed.
   */
  removeNote(e) {
    const $note = $(e.currentTarget).closest('.note');
    const noteElId = $note.attr('id');
    $(`.note[id="${noteElId}"]`).each((i, el) => {
      // A same note appears in the "Discussion" and in the "Changes" tab, we have
      // to remove all. Using $('.note[id='noteId']') ensure we get all the notes,
      // where $('#noteId') would return only one.
      const $note = $(el);
      const $notes = $note.closest('.discussion-notes');
      const discussionId = $('.notes', $notes).data('discussionId');

      $note.remove();

      // check if this is the last note for this line
      if ($notes.find('.note').length === 0) {
        const notesTr = $notes.closest('tr');

        // "Discussions" tab
        $notes.closest('.timeline-entry').remove();

        $(`.js-diff-avatars-${discussionId}`).trigger('remove.vue');

        // The notes tr can contain multiple lists of notes, like on the parallel diff
        // notesTr does not exist for image diffs
        if (notesTr.find('.discussion-notes').length > 1 || notesTr.length === 0) {
          const $diffFile = $notes.closest('.diff-file');
          if ($diffFile.length > 0) {
            const removeBadgeEvent = new CustomEvent('removeBadge.imageDiff', {
              detail: {
                // badgeNumber's start with 1 and index starts with 0
                badgeNumber: $notes.index() + 1,
              },
            });

            $diffFile[0].dispatchEvent(removeBadgeEvent);
          }

          $notes.remove();
        } else if (notesTr.length > 0) {
          notesTr.remove();
        }
      }
    });

    Notes.checkMergeRequestStatus();
    return this.updateNotesCount(-1);
  }

  /**
   * Called in response to clicking the delete attachment link
   *
   * Removes the attachment wrapper view, including image tag if it exists
   * Resets the note editing form
   */
  removeAttachment() {
    const $note = $(this).closest('.note');
    $note.find('.note-attachment').remove();
    $note.find('.note-body > .note-text').show();
    $note.find('.note-header').show();
    return $note.find('.diffs .current-note-edit-form').remove();
  }

  /**
   * Called when clicking on the "reply" button for a diff line.
   *
   * Shows the note form below the notes.
   */
  onReplyToDiscussionNote(e) {
    this.replyToDiscussionNote(e.target);
  }

  replyToDiscussionNote(target) {
    const form = this.cleanForm(this.formClone.clone());
    const replyLink = $(target).closest('.js-discussion-reply-button');
    // insert the form after the button
    replyLink.closest('.discussion-reply-holder').hide().after(form);
    // show the form
    return this.setupDiscussionNoteForm(replyLink, form);
  }

  /**
   * Shows the diff or discussion form and does some setup on it.
   *
   * Sets some hidden fields in the form.
   *
   * Note: dataHolder must have the "discussionId" and "lineCode" data attributes set.
   */
  setupDiscussionNoteForm(dataHolder, form) {
    // set up note target
    let diffFileData = dataHolder.closest('.text-file');

    if (diffFileData.length === 0) {
      diffFileData = dataHolder.closest('.image');
    }

    const discussionID = dataHolder.data('discussionId');

    if (discussionID) {
      form.attr('data-discussion-id', discussionID);
      form.find('#in_reply_to_discussion_id').val(discussionID);
    }

    form.find('#note_project_id').val(dataHolder.data('discussionProjectId'));

    form.attr('data-line-code', dataHolder.data('lineCode'));
    form.find('#line_type').val(dataHolder.data('lineType'));

    form.find('#note_noteable_type').val(diffFileData.data('noteableType'));
    form.find('#note_noteable_id').val(diffFileData.data('noteableId'));
    form.find('#note_commit_id').val(diffFileData.data('commitId'));

    form.find('#note_type').val(dataHolder.data('noteType'));

    // LegacyDiffNote
    form.find('#note_line_code').val(dataHolder.data('lineCode'));

    // DiffNote
    form.find('#note_position').val(dataHolder.attr('data-position'));

    form.append('</div>').find('.js-close-discussion-note-form').show().removeClass('hide');
    form.find('.js-note-target-close').remove();
    form.find('.js-note-new-discussion').remove();
    this.setupNoteForm(form);

    form.removeClass('js-main-target-form').addClass('discussion-form js-discussion-note-form');

    form.find('.js-note-text').focus();
    form.find('.js-comment-resolve-button').attr('data-discussion-id', discussionID);
  }

  /**
   * Called when clicking on the "add a comment" button on the side of a diff line.
   *
   * Inserts a temporary row for the form below the line.
   * Sets up the form and shows it.
   */
  onAddDiffNote(e) {
    e.preventDefault();
    const link = e.currentTarget || e.target;
    const $link = $(link);
    const showReplyInput = !$link.hasClass('js-diff-comment-avatar');
    this.toggleDiffNote({
      target: $link,
      lineType: link.dataset.lineType,
      showReplyInput,
      currentUsername: gon.current_username,
      currentUserAvatar: gon.current_user_avatar_url,
      currentUserFullname: gon.current_user_fullname,
    });
  }

  onAddImageDiffNote(e) {
    const $link = $(e.currentTarget || e.target);
    const $diffFile = $link.closest('.diff-file');

    const clickEvent = new CustomEvent('click.imageDiff', {
      detail: e,
    });

    $diffFile[0].dispatchEvent(clickEvent);

    // Set up comment form
    let newForm;
    const $noteContainer = $link.closest('.diff-viewer').find('.note-container');
    const $form = $noteContainer.find('> .discussion-form');

    if ($form.length === 0) {
      newForm = this.cleanForm(this.formClone.clone());
      newForm.appendTo($noteContainer);
    } else {
      newForm = $form;
    }

    this.setupDiscussionNoteForm($link, newForm);
  }

  toggleDiffNote({ target, lineType, forceShow, showReplyInput = false }) {
    let addForm;
    let newForm;
    let noteForm;
    let replyButton;
    let rowCssToAdd;
    const $link = $(target);
    const row = $link.closest('tr');
    const nextRow = row.next();
    let targetRow = row;
    if (nextRow.is('.notes_holder')) {
      targetRow = nextRow;
    }

    const hasNotes = nextRow.is('.notes_holder');
    addForm = false;
    let lineTypeSelector = '';
    rowCssToAdd =
      '<tr class="notes_holder js-temp-notes-holder"><td class="notes-content" colspan="3"><div class="content"></div></td></tr>';
    // In parallel view, look inside the correct left/right pane
    if (this.isParallelView()) {
      lineTypeSelector = `.${lineType}`;
      rowCssToAdd =
        '<tr class="notes_holder js-temp-notes-holder"><td class="notes_line old"></td><td class="notes-content parallel old"><div class="content"></div></td><td class="notes_line new"></td><td class="notes-content parallel new"><div class="content"></div></td></tr>';
    }
    const notesContentSelector = `.notes-content${lineTypeSelector} .content`;
    let notesContent = targetRow.find(notesContentSelector);

    if (hasNotes && showReplyInput) {
      targetRow.show();
      notesContent = targetRow.find(notesContentSelector);
      if (notesContent.length) {
        notesContent.show();
        replyButton = notesContent.find('.js-discussion-reply-button:visible');
        if (replyButton.length) {
          this.replyToDiscussionNote(replyButton[0]);
        } else {
          // In parallel view, the form may not be present in one of the panes
          noteForm = notesContent.find('.js-discussion-note-form');
          if (noteForm.length === 0) {
            addForm = true;
          }
        }
      }
    } else if (showReplyInput) {
      // add a notes row and insert the form
      row.after(rowCssToAdd);
      targetRow = row.next();
      notesContent = targetRow.find(notesContentSelector);
      addForm = true;
    } else {
      const isCurrentlyShown = targetRow.find('.content:not(:empty)').is(':visible');
      const isForced = forceShow === true || forceShow === false;
      const showNow = forceShow === true || (!isCurrentlyShown && !isForced);

      targetRow.toggleClass('hide', !showNow);
      notesContent.toggleClass('hide', !showNow);
    }

    if (addForm) {
      newForm = this.cleanForm(this.formClone.clone());
      newForm.appendTo(notesContent);
      // show the form
      return this.setupDiscussionNoteForm($link, newForm);
    }
  }

  /**
   * Called in response to "cancel" on a diff note form.
   *
   * Shows the reply button again.
   * Removes the form and if necessary it's temporary row.
   */
  removeDiscussionNoteForm(form) {
    const row = form.closest('tr');
    const glForm = form.data('glForm');
    glForm.destroy();
    form.find('.js-note-text').data('autosave').reset();
    // show the reply button (will only work for replies)
    form.prev('.discussion-reply-holder').show();
    if (row.is('.js-temp-notes-holder')) {
      // remove temporary row for diff lines
      return row.remove();
    }
    // only remove the form
    return form.remove();
  }

  cancelDiscussionForm(e) {
    e.preventDefault();
    const $form = $(e.target).closest('.js-discussion-note-form');
    const $discussionNote = $(e.target).closest('.discussion-notes');

    if ($discussionNote.length === 0) {
      // Only send blur event when the discussion form
      // is not part of a discussion note
      const $diffFile = $form.closest('.diff-file');

      if ($diffFile.length > 0) {
        const blurEvent = new CustomEvent('blur.imageDiff', {
          detail: e,
        });

        $diffFile[0].dispatchEvent(blurEvent);
      }
    }

    return this.removeDiscussionNoteForm($form);
  }

  /**
   * Called after an attachment file has been selected.
   *
   * Updates the file name for the selected attachment.
   */
  updateFormAttachment() {
    const form = $(this).closest('form');
    // get only the basename
    const filename = $(this)
      .val()
      .replace(/^.*[\\\/]/, '');
    return form.find('.js-attachment-filename').text(filename);
  }

  /**
   * Called when the tab visibility changes
   */
  visibilityChange() {
    return this.refresh();
  }

  updateTargetButtons(e) {
    let closetext;
    let reopentext;
    const textarea = $(e.target);
    const form = textarea.parents('form');
    const reopenbtn = form.find('.js-note-target-reopen');
    const closebtn = form.find('.js-note-target-close');

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
    } else {
      reopentext = reopenbtn.data('originalText');
      closetext = closebtn.data('originalText');
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
    }
  }

  putEditFormInPlace($el) {
    const $editForm = $(this.getEditFormSelector($el));
    const $note = $el.closest('.note');

    $editForm.insertAfter($note.find('.note-text'));

    const $originalContentEl = $note.find('.original-note-content');
    const originalContent = $originalContentEl.text().trim();
    const postUrl = $originalContentEl.data('postUrl');
    const targetId = $originalContentEl.data('targetId');
    const targetType = $originalContentEl.data('targetType');

    this.glForm = new GLForm($editForm.find('form'), this.enableGFM);

    $editForm.find('form').attr('action', `${postUrl}?html=true`).attr('data-remote', 'true');
    $editForm.find('.js-form-target-id').val(targetId);
    $editForm.find('.js-form-target-type').val(targetType);
    $editForm.find('.js-note-text').focus().val(originalContent);
    $editForm.find('.js-md-write-button').trigger('click');
    $editForm.find('.referenced-users').hide();
  }

  putConflictEditWarningInPlace(noteEntity, $note) {
    if ($note.find('.js-conflict-edit-warning').length === 0) {
      const open_link = `<a href="#note_${noteEntity.id}" target="_blank" rel="noopener noreferrer">`;
      const $alert = $(`<div class="js-conflict-edit-warning alert alert-danger">
        ${sprintf(
          s__(
            'Notes|This comment has changed since you started editing, please review the %{open_link}updated comment%{close_link} to ensure information is not lost',
          ),
          {
            open_link,
            close_link: '</a>',
          },
        )}
      </div>`);
      $alert.insertAfter($note.find('.note-text'));
    }
  }

  updateNotesCount(updateCount) {
    return this.notesCountBadge.text(parseInt(this.notesCountBadge.text(), 10) + updateCount);
  }

  static renderPlaceholderComponent($container) {
    const el = $container.find('.js-code-placeholder').get(0);
    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        GlSkeletonLoading,
      },
      render(createElement) {
        return createElement('gl-skeleton-loading');
      },
    });
  }

  static renderDiffContent($container, data) {
    const { discussion_html } = data;
    const lines = $(discussion_html).find('.line_holder');
    lines.addClass('fade-in');
    $container.find('.diff-content > table > tbody').prepend(lines);
    const fileHolder = $container.find('.file-holder');
    $container.find('.line-holder-placeholder').remove();
    syntaxHighlight(fileHolder);
  }

  onClickRetryLazyLoad(e) {
    const $retryButton = $(e.currentTarget);

    $retryButton.prop('disabled', true);

    return this.loadLazyDiff(e).then(() => {
      $retryButton.prop('disabled', false);
    });
  }

  loadLazyDiff(e) {
    const $container = $(e.currentTarget).closest('.js-toggle-container');
    Notes.renderPlaceholderComponent($container);

    $container.find('.js-toggle-lazy-diff').removeClass('js-toggle-lazy-diff');

    const $tableEl = $container.find('tbody');
    if ($tableEl.length === 0) return;

    const fileHolder = $container.find('.file-holder');
    const url = fileHolder.data('linesPath');

    const $errorContainer = $container.find('.js-error-lazy-load-diff');
    const $successContainer = $container.find('.js-success-lazy-load');

    /**
     * We only fetch resolved discussions.
     * Unresolved discussions don't have an endpoint being provided.
     */
    if (url) {
      return axios
        .get(url)
        .then(({ data }) => {
          // Reset state in case last request returned error
          $successContainer.removeClass('hidden');
          $errorContainer.addClass('hidden');

          Notes.renderDiffContent($container, data);
        })
        .catch(() => {
          $successContainer.addClass('hidden');
          $errorContainer.removeClass('hidden');
        });
    }
    return Promise.resolve();
  }

  toggleCommitList(e) {
    const $element = $(e.currentTarget);
    const $closestSystemCommitList = $element.siblings('.system-note-commit-list');
    const $svgChevronUpElement = $element.find('svg.js-chevron-up');
    const $svgChevronDownElement = $element.find('svg.js-chevron-down');

    $svgChevronUpElement.toggleClass('gl-display-none');
    $svgChevronDownElement.toggleClass('gl-display-none');

    $closestSystemCommitList.toggleClass('hide-shade');
  }

  /**
   * Scans system notes with `ul` elements in system note body
   * then collapse long commit list pushed by user to make it less
   * intrusive.
   */
  collapseLongCommitList() {
    const systemNotes = $('#notes-list').find('li.system-note').has('ul');

    $.each(systemNotes, (index, systemNote) => {
      const $systemNote = $(systemNote);
      const headerMessage = $systemNote
        .find('.note-text')
        .find('p')
        .first()
        .text()
        .replace(':', '');

      $systemNote.find('.note-header .system-note-message').html(headerMessage);

      if ($systemNote.find('li').length > MAX_VISIBLE_COMMIT_LIST_COUNT) {
        $systemNote.find('.note-text').addClass('system-note-commit-list');
        $systemNote.find('.system-note-commit-list-toggler').show();
      } else {
        $systemNote.find('.note-text').addClass('system-note-commit-list hide-shade');
      }
    });
  }

  addFlash(...flashParams) {
    this.flashContainer = createFlash(...flashParams);
  }

  clearFlash() {
    if (this.flashContainer) {
      this.flashContainer.style.display = 'none';
      this.flashContainer = null;
    }
  }

  cleanForm($form) {
    // Remove JS classes that are not needed here
    $form.find('.js-comment-type-dropdown').removeClass('btn-group');

    // Remove dropdown
    $form.find('.dropdown-menu').remove();

    return $form;
  }

  /**
   * Check if note does not exist on page
   */
  static isNewNote(noteEntity, noteIds) {
    return $.inArray(noteEntity.id, noteIds) === -1;
  }

  /**
   * Check if $note already contains the `noteEntity` content
   */
  static isUpdatedNote(noteEntity, $note) {
    // There can be CRLF vs LF mismatches if we don't sanitize and compare the same way
    const sanitizedNoteEntityText = normalizeNewlines(noteEntity.note.trim());
    const currentNoteText = normalizeNewlines(
      $note.find('.original-note-content').first().text().trim(),
    );
    return sanitizedNoteEntityText !== currentNoteText;
  }

  static checkMergeRequestStatus() {
    if (getPagePath(1) === 'merge_requests' && gl.mrWidget) {
      gl.mrWidget.checkStatus();
    }
  }

  static animateAppendNote(noteHtml, $notesList) {
    const $note = $(noteHtml);

    $note.addClass('fade-in-full').renderGFM();
    $notesList.append($note);
    return $note;
  }

  static animateUpdateNote(noteHtml, $note) {
    const $updatedNote = $(noteHtml);

    $updatedNote.addClass('fade-in').renderGFM();
    $note.replaceWith($updatedNote);
    return $updatedNote;
  }

  /**
   * Get data from Form attributes to use for saving/submitting comment.
   */
  getFormData($form) {
    const content = $form.find('.js-note-text').val();
    return {
      // eslint-disable-next-line no-jquery/no-serialize
      formData: $form.serialize(),
      formContent: escape(content),
      formAction: $form.attr('action'),
      formContentOriginal: content,
    };
  }

  /**
   * Identify if comment has any quick actions
   */
  hasQuickActions(formContent) {
    return REGEX_QUICK_ACTIONS.test(formContent);
  }

  /**
   * Remove quick actions and leave comment with pure message
   */
  stripQuickActions(formContent) {
    return formContent.replace(REGEX_QUICK_ACTIONS, '').trim();
  }

  /**
   * Gets appropriate description from quick actions found in provided `formContent`
   */
  getQuickActionDescription(formContent, availableQuickActions = []) {
    let tempFormContent;

    // Identify executed quick actions from `formContent`
    const executedCommands = availableQuickActions.filter((command) => {
      const commandRegex = new RegExp(`/${command.name}`);
      return commandRegex.test(formContent);
    });

    if (executedCommands && executedCommands.length) {
      if (executedCommands.length > 1) {
        tempFormContent = __('Applying multiple commands');
      } else {
        const commandDescription = executedCommands[0].description.toLowerCase();
        tempFormContent = sprintf(__('Applying command to %{commandDescription}'), {
          commandDescription,
        });
      }
    } else {
      tempFormContent = __('Applying command');
    }

    return tempFormContent;
  }

  /**
   * Create placeholder note DOM element populated with comment body
   * that we will show while comment is being posted.
   * Once comment is _actually_ posted on server, we will have final element
   * in response that we will show in place of this temporary element.
   */
  createPlaceholderNote({
    formContent,
    uniqueId,
    isDiscussionNote,
    currentUsername,
    currentUserFullname,
    currentUserAvatar,
  }) {
    const discussionClass = isDiscussionNote ? 'discussion' : '';
    const $tempNote = $(
      `<li id="${uniqueId}" class="note being-posted fade-in-half timeline-entry">
         <div class="timeline-entry-inner">
            <div class="timeline-icon">
               <a href="/${escape(currentUsername)}">
                 <img class="avatar s40" src="${currentUserAvatar}" />
               </a>
            </div>
            <div class="timeline-content ${discussionClass}">
               <div class="note-header">
                  <div class="note-header-info">
                     <a href="/${escape(currentUsername)}">
                       <span class="d-none d-sm-inline-block bold">${escape(currentUsername)}</span>
                       <span class="note-headline-light">${escape(currentUsername)}</span>
                     </a>
                  </div>
               </div>
               <div class="note-body">
                 <div class="note-text">
                   <p>${formContent}</p>
                 </div>
               </div>
            </div>
         </div>
      </li>`,
    );

    $tempNote.find('.d-none.d-sm-inline-block').text(escape(currentUserFullname));
    $tempNote.find('.note-headline-light').text(`@${escape(currentUsername)}`);

    return $tempNote;
  }

  /**
   * Create Placeholder System Note DOM element populated with quick action description
   */
  createPlaceholderSystemNote({ formContent, uniqueId }) {
    const $tempNote = $(
      `<li id="${uniqueId}" class="note system-note timeline-entry being-posted fade-in-half">
         <div class="timeline-entry-inner">
           <div class="timeline-content">
             <i>${formContent}</i>
           </div>
         </div>
       </li>`,
    );

    return $tempNote;
  }

  /**
   * This method does following tasks step-by-step whenever a new comment
   * is submitted by user (both main thread comments as well as discussion comments).
   *
   * 1) Get Form metadata
   * 2) Identify comment type; a) Main thread b) Discussion thread c) Discussion resolve
   * 3) Build temporary placeholder element (using `createPlaceholderNote`)
   * 4) Show placeholder note on UI
   * 5) Perform network request to submit the note using `axios.post`
   *    a) If request is successfully completed
   *        1. Remove placeholder element
   *        2. Show submitted Note element
   *        3. Perform post-submit errands
   *           a. Mark discussion as resolved if comment submission was for resolve.
   *           b. Reset comment form to original state.
   *    b) If request failed
   *        1. Remove placeholder element
   *        2. Show error Flash message about failure
   */
  postComment(e) {
    e.preventDefault();

    // Get Form metadata
    const $submitBtn = $(e.target);
    $submitBtn.prop('disabled', true);
    let $form = $submitBtn.parents('form');
    const $closeBtn = $form.find('.js-note-target-close');
    const isDiscussionNote =
      $submitBtn.parent().find('li.droplab-item-selected').attr('id') === 'discussion';
    const isMainForm = $form.hasClass('js-main-target-form');
    const isDiscussionForm = $form.hasClass('js-discussion-note-form');
    const isDiscussionResolve = $submitBtn.hasClass('js-comment-resolve-button');
    const { formData, formContent, formAction, formContentOriginal } = this.getFormData($form);
    let noteUniqueId;
    let systemNoteUniqueId;
    let hasQuickActions = false;
    let $notesContainer;
    let tempFormContent;

    // Get reference to notes container based on type of comment
    if (isDiscussionForm) {
      $notesContainer = $form.parent('.discussion-notes').find('.notes');
    } else if (isMainForm) {
      $notesContainer = $('ul.main-notes-list');
    }

    // If comment is to resolve discussion, disable submit buttons while
    // comment posting is finished.
    if (isDiscussionResolve) {
      $form.find('.js-comment-submit-button').disable();
    }

    tempFormContent = formContent;
    if (this.glForm.supportsQuickActions && this.hasQuickActions(formContent)) {
      tempFormContent = this.stripQuickActions(formContent);
      hasQuickActions = true;
    }

    // Show placeholder note
    if (tempFormContent) {
      noteUniqueId = uniqueId('tempNote_');
      $notesContainer.append(
        this.createPlaceholderNote({
          formContent: tempFormContent,
          uniqueId: noteUniqueId,
          isDiscussionNote,
          currentUsername: gon.current_username,
          currentUserFullname: gon.current_user_fullname,
          currentUserAvatar: gon.current_user_avatar_url,
        }),
      );
    }

    // Show placeholder system note
    if (hasQuickActions) {
      systemNoteUniqueId = uniqueId('tempSystemNote_');
      $notesContainer.append(
        this.createPlaceholderSystemNote({
          formContent: this.getQuickActionDescription(
            formContent,
            AjaxCache.get(gl.GfmAutoComplete.dataSources.commands),
          ),
          uniqueId: systemNoteUniqueId,
        }),
      );
    }

    // Clear the form textarea
    if ($notesContainer.length) {
      if (isMainForm) {
        this.resetMainTargetForm(e);
      } else if (isDiscussionForm) {
        this.removeDiscussionNoteForm($form);
      }
    }

    $closeBtn.text($closeBtn.data('originalText'));

    // Make request to submit comment on server
    return axios
      .post(`${formAction}?html=true`, formData)
      .then((res) => {
        const note = res.data;

        $submitBtn.prop('disabled', false);
        // Submission successful! remove placeholder
        $notesContainer.find(`#${noteUniqueId}`).remove();

        const $diffFile = $form.closest('.diff-file');
        if ($diffFile.length > 0) {
          const blurEvent = new CustomEvent('blur.imageDiff', {
            detail: e,
          });

          $diffFile[0].dispatchEvent(blurEvent);
        }

        // Reset cached commands list when command is applied
        if (hasQuickActions) {
          $form.find('textarea.js-note-text').trigger('clear-commands-cache.atwho');
        }

        // Clear previous form errors
        this.clearFlashWrapper();

        // Check if this was discussion comment
        if (isDiscussionForm) {
          // Remove flash-container
          $notesContainer.find('.flash-container').remove();

          // If comment intends to resolve discussion, do the same.
          if (isDiscussionResolve) {
            $form
              .attr('data-discussion-id', $submitBtn.data('discussionId'))
              .attr('data-resolve-all', 'true')
              .attr('data-project-path', $submitBtn.data('projectPath'));
          }

          // Show final note element on UI
          const isNewDiffComment = $notesContainer.length === 0;
          this.addDiscussionNote($form, note, isNewDiffComment);

          if (isNewDiffComment) {
            // Add image badge, avatar badge and toggle discussion badge for new image diffs
            const notePosition = $form.find('#note_position').val();
            if ($diffFile.length > 0 && notePosition.length > 0) {
              const { x, y, width, height } = JSON.parse(notePosition);
              const addBadgeEvent = new CustomEvent('addBadge.imageDiff', {
                detail: {
                  x,
                  y,
                  width,
                  height,
                  noteId: `note_${note.id}`,
                  discussionId: note.discussion_id,
                },
              });

              $diffFile[0].dispatchEvent(addBadgeEvent);
            }
          }

          // append flash-container to the Notes list
          if ($notesContainer.length) {
            $notesContainer.append('<div class="flash-container" style="display: none;"></div>');
          }
        } else if (isMainForm) {
          // Check if this was main thread comment
          // Show final note element on UI and perform form and action buttons cleanup
          this.addNote($form, note);
          this.reenableTargetFormSubmitButton(e);
        }

        if (note.commands_changes) {
          this.handleQuickActions(note);
        }

        $form.trigger('ajax:success', [note]);
      })
      .catch(() => {
        // Submission failed, remove placeholder note and show Flash error message
        $notesContainer.find(`#${noteUniqueId}`).remove();
        $submitBtn.prop('disabled', false);
        const blurEvent = new CustomEvent('blur.imageDiff', {
          detail: e,
        });

        const closestDiffFile = $form.closest('.diff-file');

        if (closestDiffFile.length) {
          closestDiffFile[0].dispatchEvent(blurEvent);
        }

        if (hasQuickActions) {
          $notesContainer.find(`#${systemNoteUniqueId}`).remove();
        }

        // Show form again on UI on failure
        if (isDiscussionForm && $notesContainer.length) {
          const replyButton = $notesContainer.parent().find('.js-discussion-reply-button');
          this.replyToDiscussionNote(replyButton[0]);
          $form = $notesContainer.parent().find('form');
        }

        $form.find('.js-note-text').val(formContentOriginal);
        this.reenableTargetFormSubmitButton(e);
        this.addNoteError($form);
      });
  }

  /**
   * This method does following tasks step-by-step whenever an existing comment
   * is updated by user (both main thread comments as well as discussion comments).
   *
   * 1) Get Form metadata
   * 2) Update note element with new content
   * 3) Perform network request to submit the updated note using `axios.post`
   *    a) If request is successfully completed
   *        1. Show submitted Note element
   *    b) If request failed
   *        1. Revert Note element to original content
   *        2. Show error Flash message about failure
   */
  updateComment(e) {
    e.preventDefault();

    // Get Form metadata
    const $submitBtn = $(e.target);
    const $form = $submitBtn.parents('form');
    const $closeBtn = $form.find('.js-note-target-close');
    const $editingNote = $form.parents('.note.is-editing');
    const $noteBody = $editingNote.find('.js-task-list-container');
    const $noteBodyText = $noteBody.find('.note-text');
    const { formData, formContent, formAction } = this.getFormData($form);

    // Cache original comment content
    const cachedNoteBodyText = $noteBodyText.html();

    // Show updated comment content temporarily
    $noteBodyText.html(formContent);
    $editingNote.removeClass('is-editing fade-in-full').addClass('being-posted fade-in-half');
    $editingNote
      .find('.note-headline-meta a')
      .html('<span class="spinner align-text-bottom"></span>');

    // Make request to update comment on server
    axios
      .post(`${formAction}?html=true`, formData)
      .then(({ data }) => {
        // Submission successful! render final note element
        this.updateNote(data, $editingNote);
      })
      .catch(() => {
        // Submission failed, revert back to original note
        $noteBodyText.html(escape(cachedNoteBodyText));
        $editingNote.removeClass('being-posted fade-in');
        $editingNote.find('.gl-spinner').remove();

        // Show Flash message about failure
        this.updateNoteError();
      });

    return $closeBtn.text($closeBtn.data('originalText'));
  }
}

window.Notes = Notes;
