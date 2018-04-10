/* eslint-disable func-names, no-var, object-shorthand, comma-dangle, prefer-arrow-callback */

import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

// MarkdownPreview
//
// Handles toggling the "Write" and "Preview" tab clicks, rendering the preview
// (including the explanation of quick actions), and showing a warning when
// more than `x` users are referenced.
//

var lastTextareaPreviewed;
var lastTextareaHeight = null;
var markdownPreview;
var previewButtonSelector;
var writeButtonSelector;

function MarkdownPreview() {}

// Minimum number of users referenced before triggering a warning
MarkdownPreview.prototype.referenceThreshold = 10;
MarkdownPreview.prototype.emptyMessage = 'Nothing to preview.';

MarkdownPreview.prototype.ajaxCache = {};

MarkdownPreview.prototype.showPreview = function ($form) {
  var mdText;
  var preview = $form.find('.js-md-preview');
  var url = preview.data('url');
  if (preview.hasClass('md-preview-loading')) {
    return;
  }
  mdText = $form.find('textarea.markdown-area').val();

  if (mdText.trim().length === 0) {
    preview.text(this.emptyMessage);
    this.hideReferencedUsers($form);
  } else {
    preview.addClass('md-preview-loading').text('Loading...');
    this.fetchMarkdownPreview(mdText, url, (function (response) {
      var body;
      if (response.body.length > 0) {
        body = response.body;
      } else {
        body = this.emptyMessage;
      }

      preview.removeClass('md-preview-loading').html(body);
      preview.renderGFM();
      this.renderReferencedUsers(response.references.users, $form);

      if (response.references.commands) {
        this.renderReferencedCommands(response.references.commands, $form);
      }
    }).bind(this));
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
  axios.post(url, {
    text,
  })
  .then(({ data }) => {
    this.ajaxCache = {
      text: text,
      response: data,
    };
    success(data);
  })
  .catch(() => flash(__('An error occurred while fetching markdown preview')));
};

MarkdownPreview.prototype.hideReferencedUsers = function ($form) {
  $form.find('.referenced-users').hide();
};

MarkdownPreview.prototype.renderReferencedUsers = function (users, $form) {
  var referencedUsers;
  referencedUsers = $form.find('.referenced-users');
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
  var referencedCommands;
  referencedCommands = $form.find('.referenced-commands');
  if (commands.length > 0) {
    referencedCommands.html(commands);
    referencedCommands.show();
  } else {
    referencedCommands.html('');
    referencedCommands.hide();
  }
};

markdownPreview = new MarkdownPreview();

previewButtonSelector = '.js-md-preview-button';
writeButtonSelector = '.js-md-write-button';
lastTextareaPreviewed = null;
const markdownToolbar = $('.md-header-toolbar');

$.fn.setupMarkdownPreview = function () {
  var $form = $(this);
  $form.find('textarea.markdown-area').on('input', function () {
    markdownPreview.hideReferencedUsers($form);
  });
};

$(document).on('markdown-preview:show', function (e, $form) {
  if (!$form) {
    return;
  }

  lastTextareaPreviewed = $form.find('textarea.markdown-area');
  lastTextareaHeight = lastTextareaPreviewed.height();

  // toggle tabs
  $form.find(writeButtonSelector).parent().removeClass('active');
  $form.find(previewButtonSelector).parent().addClass('active');

  // toggle content
  $form.find('.md-write-holder').hide();
  $form.find('.md-preview-holder').show();
  markdownToolbar.removeClass('active');
  markdownPreview.showPreview($form);
});

$(document).on('markdown-preview:hide', function (e, $form) {
  if (!$form) {
    return;
  }
  lastTextareaPreviewed = null;

  if (lastTextareaHeight) {
    $form.find('textarea.markdown-area').height(lastTextareaHeight);
  }

  // toggle tabs
  $form.find(writeButtonSelector).parent().addClass('active');
  $form.find(previewButtonSelector).parent().removeClass('active');

  // toggle content
  $form.find('.md-write-holder').show();
  $form.find('textarea.markdown-area').focus();
  $form.find('.md-preview-holder').hide();
  markdownToolbar.addClass('active');

  markdownPreview.hideReferencedCommands($form);
});

$(document).on('markdown-preview:toggle', function (e, keyboardEvent) {
  var $target;
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
  var $form;
  e.preventDefault();
  $form = $(this).closest('form');
  $(document).triggerHandler('markdown-preview:show', [$form]);
});

$(document).on('click', writeButtonSelector, function (e) {
  var $form;
  e.preventDefault();
  $form = $(this).closest('form');
  $(document).triggerHandler('markdown-preview:hide', [$form]);
});

export default MarkdownPreview;
