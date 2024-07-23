/* eslint-disable func-names */

import $ from 'jquery';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

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
  const preview = $form.find('.js-md-preview');
  const url = preview.data('url');
  if (preview.hasClass('md-preview-loading')) {
    return;
  }

  const mdText = $form.find('textarea.markdown-area').val();

  if (mdText === undefined) {
    return;
  }

  if (mdText.trim().length === 0) {
    preview.text(this.emptyMessage);
    this.hideReferencedUsers($form);
  } else {
    preview.addClass('md-preview-loading').text(__('Loading...'));
    this.fetchMarkdownPreview(mdText, url, (response) => {
      let body;
      if (response.body.length > 0) {
        ({ body } = response);
      } else {
        body = this.emptyMessage;
      }

      preview.removeClass('md-preview-loading').html(body);
      renderGFM(preview.get(0));
      this.renderReferencedUsers(response.references.users, $form);

      if (response.references.commands) {
        this.renderReferencedCommands(response.references.commands, $form);
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

MarkdownPreview.prototype.hideReferencedUsers = function ($form) {
  $form.find('.referenced-users').hide();
};

MarkdownPreview.prototype.renderReferencedUsers = function (users, $form) {
  const referencedUsers = $form.find('.referenced-users');
  if (referencedUsers.length) {
    if (users.length >= this.referenceThreshold) {
      referencedUsers.show();
      referencedUsers.find('.js-referenced-users-count').text(users.length);
    } else {
      referencedUsers.hide();
    }
  }
};

MarkdownPreview.prototype.hideReferencedCommands = function ($form) {
  $form.find('.referenced-commands').hide();
};

MarkdownPreview.prototype.renderReferencedCommands = function (commands, $form) {
  const referencedCommands = $form.find('.referenced-commands');
  if (commands.length > 0) {
    referencedCommands.html(commands);
    referencedCommands.show();
  } else {
    referencedCommands.html('');
    referencedCommands.hide();
  }
};

const markdownPreview = new MarkdownPreview();

const previewButtonSelector = '.js-md-preview-button';
lastTextareaPreviewed = null;

$(document).on('markdown-preview:show', (e, $form) => {
  if (!$form) {
    return;
  }

  lastTextareaPreviewed = $form.find('textarea.markdown-area');
  lastTextareaHeight = lastTextareaPreviewed.height();

  const $previewButton = $form.find(previewButtonSelector);

  if (!$previewButton.parents('.js-vue-markdown-field').length) {
    $previewButton.val('edit');
    $previewButton.children('span.gl-button-text').text(__('Continue editing'));
    $previewButton.addClass('!gl-shadow-none !gl-bg-transparent');
  }

  // toggle content
  $form.find('.md-write-holder').hide();
  $form.find('.md-preview-holder').show();
  $form.find('.haml-markdown-button, .js-zen-enter').addClass('!gl-hidden');

  markdownPreview.showPreview($form);
});

$(document).on('markdown-preview:hide', (e, $form) => {
  if (!$form) {
    return;
  }
  lastTextareaPreviewed = null;

  if (lastTextareaHeight) {
    $form.find('textarea.markdown-area').height(lastTextareaHeight);
  }

  const $previewButton = $form.find(previewButtonSelector);

  if (!$previewButton.parents('.js-vue-markdown-field').length) {
    $previewButton.val('preview');
    $previewButton.children('span.gl-button-text').text(__('Preview'));
  }

  // toggle content
  $form.find('.md-write-holder').show();
  $form.find('textarea.markdown-area').focus();
  $form.find('.md-preview-holder').hide();
  $form.find('.haml-markdown-button, .js-zen-enter').removeClass('!gl-hidden');

  markdownPreview.hideReferencedCommands($form);
});

$(document).on('markdown-preview:toggle', (e, keyboardEvent) => {
  let $target;
  $target = $(keyboardEvent.target);
  if ($target.is('textarea.markdown-area')) {
    $(document).triggerHandler('markdown-preview:show', [$target.closest('form')]);
    keyboardEvent.preventDefault();
  } else if (lastTextareaPreviewed) {
    $target = lastTextareaPreviewed;
    $(document).triggerHandler('markdown-preview:hide', [$target.closest('form')]);
    keyboardEvent.preventDefault();
  }
});

$(document).on('click', previewButtonSelector, function (e) {
  e.preventDefault();
  const $form = $(this).closest('form');
  const eventName = e.currentTarget.getAttribute('value') === 'preview' ? 'show' : 'hide';
  $(document).triggerHandler(`markdown-preview:${eventName}`, [$form]);
});

$(document).on('mousedown', previewButtonSelector, function (e) {
  e.preventDefault();
  const $form = $(this).closest('form');
  $form.find(previewButtonSelector).removeClass('!gl-shadow-none !gl-bg-transparent');
});

$(document).on('mouseenter', previewButtonSelector, function (e) {
  e.preventDefault();
  const $form = $(this).closest('form');
  $form.find(previewButtonSelector).removeClass('!gl-bg-transparent');
});

$(document).on('mouseleave', previewButtonSelector, function (e) {
  e.preventDefault();
  const $form = $(this).closest('form');
  $form.find(previewButtonSelector).addClass('!gl-bg-transparent');
});

export default MarkdownPreview;
