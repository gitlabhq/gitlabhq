/* eslint-disable func-names */

import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { toggleDisplay } from '~/lib/utils/dom_utils';

export const MARKDOWN_EVENT_SHOW = 'markdown-preview:show';
export const MARKDOWN_EVENT_HIDE = 'markdown-preview:hide';
export const MARKDOWN_EVENT_TOGGLE = 'markdown-preview:toggle';

// MarkdownPreview
//
// Handles toggling the "Write" and "Preview" tab clicks, rendering the preview
// (including the explanation of quick actions), and showing a warning when
// more than `x` users are referenced.
//

let lastTextareaHeight;
let lastTextareaPreviewed;

function MarkdownPreview() {}

// Minimum number of users referenced before triggering a warning
MarkdownPreview.prototype.referenceThreshold = 10;
MarkdownPreview.prototype.emptyMessage = __('Nothing to preview.');

MarkdownPreview.prototype.ajaxCache = {};

MarkdownPreview.prototype.showPreview = function ($form) {
  // jQuery check can be removed once dropzone_input.js no longer uses jQuery,
  // as it is the last file importing this module that still relies on it.
  const form = $form.jquery ? $form.get(0) : $form;
  const preview = form.querySelector('.js-md-preview');
  if (!preview) {
    return;
  }
  const { url } = preview.dataset;
  if (preview.classList.contains('md-preview-loading')) {
    return;
  }

  const textarea = form.querySelector('textarea.markdown-area');
  const mdText = textarea?.value;

  if (mdText === undefined) {
    return;
  }

  if (mdText.trim().length === 0) {
    preview.textContent = this.emptyMessage;
    this.hideReferencedUsers(form);
  } else {
    preview.classList.add('md-preview-loading');
    preview.textContent = __('Loading…');
    this.fetchMarkdownPreview(mdText, url, (response) => {
      const { body = this.emptyMessage } = response;

      preview.classList.remove('md-preview-loading');
      // eslint-disable-next-line no-unsanitized/property -- backend returns pre-rendered HTML, jQuery version used .html() without sanitizing
      preview.innerHTML = body;
      renderGFM(preview);
      this.renderReferencedUsers(response.references.users, form);

      if (response.references.commands) {
        this.renderReferencedCommands(response.references.commands, form);
      }
    });
  }
};

MarkdownPreview.prototype.fetchMarkdownPreview = function (text, url, success) {
  if (!url) {
    return;
  }
  if (text === this.ajaxCache.text) {
    success(this.ajaxCache.response);
    return;
  }
  axios
    .post(url, {
      text,
    })
    .then(({ data }) => {
      this.ajaxCache = {
        text,
        response: data,
      };
      success(data);
    })
    .catch(() =>
      createAlert({
        message: __('An error occurred while fetching Markdown preview'),
      }),
    );
};

MarkdownPreview.prototype.hideReferencedUsers = function (form) {
  toggleDisplay(form.querySelector('.referenced-users'), false);
};

MarkdownPreview.prototype.renderReferencedUsers = function (users, form) {
  const referencedUsers = form.querySelector('.referenced-users');
  if (referencedUsers) {
    if (users.length >= this.referenceThreshold) {
      toggleDisplay(referencedUsers, true);
      const countEl = referencedUsers.querySelector('.js-referenced-users-count');
      if (countEl) {
        countEl.textContent = users.length;
      }
    } else {
      toggleDisplay(referencedUsers, false);
    }
  }
};

MarkdownPreview.prototype.hideReferencedCommands = function (form) {
  // jQuery check can be removed once dropzone_input.js no longer uses jQuery,
  // as it is the last file importing this module that still relies on it.
  const formEl = form.jquery ? form.get(0) : form;
  toggleDisplay(formEl.querySelector('.referenced-commands'), false);
};

MarkdownPreview.prototype.renderReferencedCommands = function (commands, form) {
  const referencedCommands = form.querySelector('.referenced-commands');
  if (!referencedCommands) {
    return;
  }
  if (commands.length > 0) {
    // eslint-disable-next-line no-unsanitized/property -- backend returns pre-rendered HTML, jQuery version used .html() without sanitizing
    referencedCommands.innerHTML = commands;
    toggleDisplay(referencedCommands, true);
  } else {
    referencedCommands.textContent = '';
    toggleDisplay(referencedCommands, false);
  }
};

const markdownPreview = new MarkdownPreview();

const previewButtonSelector = '.js-md-preview-button';
lastTextareaPreviewed = null;

function getGFMPreviewButtons(e) {
  const previewButton = e.target?.closest?.(previewButtonSelector);
  if (!previewButton) return [];
  e.preventDefault();
  return previewButton.closest('form')?.querySelectorAll(previewButtonSelector) ?? [];
}

document.addEventListener(MARKDOWN_EVENT_SHOW, (e) => {
  const form = e.detail?.form;
  if (!form) {
    return;
  }

  lastTextareaPreviewed = form.querySelector('textarea.markdown-area');
  lastTextareaHeight = lastTextareaPreviewed?.offsetHeight;

  const previewButton = form.querySelector(previewButtonSelector);

  if (previewButton && !previewButton.closest('.js-vue-markdown-field')) {
    previewButton.value = 'edit';
    const buttonText = previewButton.querySelector('span.gl-button-text');
    if (buttonText) buttonText.textContent = __('Continue editing');
    previewButton.classList.add('!gl-shadow-none', '!gl-bg-transparent');
  }

  // toggle content
  toggleDisplay(form.querySelector('.md-write-holder'), false);
  toggleDisplay(form.querySelector('.md-preview-holder'), true);
  form
    .querySelectorAll('.haml-markdown-button, .js-zen-enter')
    .forEach((el) => el.classList.add('!gl-hidden'));

  markdownPreview.showPreview(form);
});

document.addEventListener(MARKDOWN_EVENT_HIDE, (e) => {
  const form = e.detail?.form;
  if (!form) {
    return;
  }
  lastTextareaPreviewed = null;

  if (lastTextareaHeight) {
    const textarea = form.querySelector('textarea.markdown-area');
    if (textarea) textarea.style.height = `${lastTextareaHeight}px`;
  }

  const previewButton = form.querySelector(previewButtonSelector);

  if (previewButton && !previewButton.closest('.js-vue-markdown-field')) {
    previewButton.value = 'preview';
    const buttonText = previewButton.querySelector('span.gl-button-text');
    if (buttonText) buttonText.textContent = __('Preview');
  }

  // toggle content
  toggleDisplay(form.querySelector('.md-write-holder'), true);
  form.querySelector('textarea.markdown-area')?.focus();
  toggleDisplay(form.querySelector('.md-preview-holder'), false);
  form
    .querySelectorAll('.haml-markdown-button, .js-zen-enter')
    .forEach((el) => el.classList.remove('!gl-hidden'));

  markdownPreview.hideReferencedCommands(form);
});

document.addEventListener(MARKDOWN_EVENT_TOGGLE, (e) => {
  const keyboardEvent = e.detail?.keyboardEvent;
  if (!keyboardEvent) return;

  const { target } = keyboardEvent;
  if (target?.matches?.('textarea.markdown-area')) {
    document.dispatchEvent(
      new CustomEvent(MARKDOWN_EVENT_SHOW, { detail: { form: target.closest('form') } }),
    );
    keyboardEvent.preventDefault();
  } else if (lastTextareaPreviewed) {
    document.dispatchEvent(
      new CustomEvent(MARKDOWN_EVENT_HIDE, {
        detail: { form: lastTextareaPreviewed.closest('form') },
      }),
    );
    keyboardEvent.preventDefault();
  }
});

document.addEventListener('click', (e) => {
  const previewButton = e.target?.closest?.(previewButtonSelector);
  if (!previewButton) return;
  if (previewButton.closest('.js-vue-markdown-field')) return;

  e.preventDefault();
  const form = previewButton.closest('form');
  const eventName =
    previewButton.getAttribute('value') === 'preview' ? MARKDOWN_EVENT_SHOW : MARKDOWN_EVENT_HIDE;
  document.dispatchEvent(new CustomEvent(eventName, { detail: { form } }));
});

document.addEventListener('mousedown', (e) => {
  getGFMPreviewButtons(e).forEach((btn) =>
    btn.classList.remove('!gl-shadow-none', '!gl-bg-transparent'),
  );
});

document.addEventListener(
  'mouseenter',
  (e) => {
    getGFMPreviewButtons(e).forEach((btn) => btn.classList.remove('!gl-bg-transparent'));
  },
  true,
);

document.addEventListener(
  'mouseleave',
  (e) => {
    getGFMPreviewButtons(e).forEach((btn) => btn.classList.add('!gl-bg-transparent'));
  },
  true,
);

export default MarkdownPreview;
