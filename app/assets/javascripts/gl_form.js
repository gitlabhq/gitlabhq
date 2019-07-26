import $ from 'jquery';
import autosize from 'autosize';
import GfmAutoComplete, { defaultAutocompleteConfig } from 'ee_else_ce/gfm_auto_complete';
import dropzoneInput from './dropzone_input';
import { addMarkdownListeners, removeMarkdownListeners } from './lib/utils/text_markdown';
import IndentHelper from './helpers/indent_helper';
import { keystroke } from './lib/utils/common_utils';
import * as keys from './lib/utils/keycodes';
import UndoStack from './lib/utils/undo_stack';

export default class GLForm {
  constructor(form, enableGFM = {}) {
    this.handleKeyShortcuts = this.handleKeyShortcuts.bind(this);
    this.setState = this.setState.bind(this);

    this.form = form;
    this.textarea = this.form.find('textarea.js-gfm-input');
    this.enableGFM = Object.assign({}, defaultAutocompleteConfig, enableGFM);
    // Disable autocomplete for keywords which do not have dataSources available
    const dataSources = (gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources) || {};
    Object.keys(this.enableGFM).forEach(item => {
      if (item !== 'emojis') {
        this.enableGFM[item] = Boolean(dataSources[item]);
      }
    });

    this.undoStack = new UndoStack();
    this.indentHelper = new IndentHelper(this.textarea[0]);

    // Before we start, we should clean up any previous data for this form
    this.destroy();
    // Set up the form
    this.setupForm();
    this.form.data('glForm', this);
  }

  destroy() {
    // Clean form listeners
    this.clearEventListeners();
    if (this.autoComplete) {
      this.autoComplete.destroy();
    }
    this.form.data('glForm', null);
  }

  setupForm() {
    const isNewForm = this.form.is(':not(.gfm-form)');
    this.form.removeClass('js-new-note-form');
    if (isNewForm) {
      this.form.find('.div-dropzone').remove();
      this.form.addClass('gfm-form');
      // remove notify commit author checkbox for non-commit notes
      gl.utils.disableButtonIfEmptyField(
        this.form.find('.js-note-text'),
        this.form.find('.js-comment-button, .js-note-new-discussion'),
      );
      this.autoComplete = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
      this.autoComplete.setup(this.form.find('.js-gfm-input'), this.enableGFM);
      dropzoneInput(this.form);
      autosize(this.textarea);
    }
    // form and textarea event listeners
    this.addEventListeners();
    addMarkdownListeners(this.form);
    this.form.show();
    if (this.isAutosizeable) this.setupAutosize();
  }

  setupAutosize() {
    this.textarea.off('autosize:resized').on('autosize:resized', this.setHeightData.bind(this));

    this.textarea.off('mouseup.autosize').on('mouseup.autosize', this.destroyAutosize.bind(this));

    setTimeout(() => {
      autosize(this.textarea);
      this.textarea.css('resize', 'vertical');
    }, 0);
  }

  setHeightData() {
    this.textarea.data('height', this.textarea.outerHeight());
  }

  destroyAutosize() {
    const outerHeight = this.textarea.outerHeight();

    if (this.textarea.data('height') === outerHeight) return;

    autosize.destroy(this.textarea);

    this.textarea.data('height', outerHeight);
    this.textarea.outerHeight(outerHeight);
    this.textarea.css('max-height', window.outerHeight);
  }

  clearEventListeners() {
    this.textarea.off('focus');
    this.textarea.off('blur');
    this.textarea.off('keydown');
    removeMarkdownListeners(this.form);
  }

  setState(state) {
    const selection = [this.textarea[0].selectionStart, this.textarea[0].selectionEnd];
    this.textarea.val(state);
    this.textarea[0].setSelectionRange(selection[0], selection[1]);
  }

  /*
   Handle keypresses for a custom undo/redo stack.
   We need this because the toolbar buttons and indentation helpers mess with the browser's
   native undo/redo capability.
   */
  handleUndo(event) {
    const content = this.textarea.val();
    const { selectionStart, selectionEnd } = this.textarea[0];
    const stack = this.undoStack;

    if (stack.isEmpty()) {
      // ==== Save initial state in undo history ====
      stack.save(content);
    }

    if (keystroke(event, keys.Z_KEY_CODE, 'l')) {
      // ==== Undo ====
      event.preventDefault();
      stack.save(content);
      if (stack.canUndo()) {
        this.setState(stack.undo());
      }
    } else if (keystroke(event, keys.Z_KEY_CODE, 'ls') || keystroke(event, keys.Y_KEY_CODE, 'l')) {
      // ==== Redo ====
      event.preventDefault();
      if (stack.canRedo()) {
        this.setState(stack.redo());
      }
    } else if (
      keystroke(event, keys.SPACE_KEY_CODE) ||
      keystroke(event, keys.ENTER_KEY_CODE) ||
      selectionStart !== selectionEnd
    ) {
      // ==== Save after finishing a word or before deleting a large selection ====
      stack.save(content);
    } else if (content === '') {
      // ==== Save after deleting everything ====
      stack.save('');
    } else {
      // ==== Save after 1 second of inactivity ====
      stack.scheduleSave(content);
    }
  }

  handleIndent(event) {
    if (keystroke(event, keys.LEFT_BRACKET_KEY_CODE, 'l')) {
      // ==== Unindent selected lines ====
      event.preventDefault();
      this.indentHelper.unindent();
    } else if (keystroke(event, keys.RIGHT_BRACKET_KEY_CODE, 'l')) {
      // ==== Indent selected lines ====
      event.preventDefault();
      this.indentHelper.indent();
    } else if (keystroke(event, keys.ENTER_KEY_CODE)) {
      // ==== Auto-indent new lines ====
      event.preventDefault();
      this.indentHelper.newline();
    } else if (keystroke(event, keys.BACKSPACE_KEY_CODE)) {
      // ==== Auto-delete indents at the beginning of the line ====
      this.indentHelper.backspace(event);
    }
  }

  handleKeyShortcuts(event) {
    this.handleIndent(event);
    this.handleUndo(event);
  }

  addEventListeners() {
    this.textarea.on('focus', function focusTextArea() {
      $(this)
        .closest('.md-area')
        .addClass('is-focused');
    });
    this.textarea.on('blur', function blurTextArea() {
      $(this)
        .closest('.md-area')
        .removeClass('is-focused');
    });
    this.textarea.on('keydown', e => this.handleKeyShortcuts(e.originalEvent));
  }
}
