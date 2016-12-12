/* eslint-disable func-names, space-before-function-paren, no-var, one-var, one-var-declaration-per-line, wrap-iife, no-else-return, consistent-return, object-shorthand, comma-dangle, no-param-reassign, padded-blocks, camelcase, prefer-arrow-callback, max-len */

// MarkdownPreview
//
// Handles toggling the "Write" and "Preview" tab clicks, rendering the preview,
// and showing a warning when more than `x` users are referenced.
//
(function() {
  var lastTextareaPreviewed, markdownPreview, previewButtonSelector, writeButtonSelector;

  window.MarkdownPreview = (function() {
    function MarkdownPreview() {}

    // Minimum number of users referenced before triggering a warning
    MarkdownPreview.prototype.referenceThreshold = 10;

    MarkdownPreview.prototype.ajaxCache = {};

    MarkdownPreview.prototype.showPreview = function(form) {
      var mdText, preview;
      preview = form.find('.js-md-preview');
      mdText = form.find('textarea.markdown-area').val();
      if (mdText.trim().length === 0) {
        preview.text('Nothing to preview.');
        this.hideReferencedUsers(form);
      } else {
        preview.text('Loading...');
        this.renderMarkdown(mdText, (function(response) {
          preview.html(response.body);
          preview.renderGFM();
          this.renderReferencedUsers(response.references.users, form);
        }).bind(this));
      }
    };

    MarkdownPreview.prototype.renderMarkdown = function(text, success) {
      if (!window.preview_markdown_path) {
        return;
      }
      if (text === this.ajaxCache.text) {
        success(this.ajaxCache.response);
        return;
      }
      $.ajax({
        type: 'POST',
        url: window.preview_markdown_path,
        data: {
          text: text
        },
        dataType: 'json',
        success: (function(response) {
          this.ajaxCache = {
            text: text,
            response: response
          };
          success(response);
        }).bind(this)
      });
    };

    MarkdownPreview.prototype.hideReferencedUsers = function(form) {
      form.find('.referenced-users').hide();
    };

    MarkdownPreview.prototype.renderReferencedUsers = function(users, form) {
      var referencedUsers;
      referencedUsers = form.find('.referenced-users');
      if (referencedUsers.length) {
        if (users.length >= this.referenceThreshold) {
          referencedUsers.show();
          referencedUsers.find('.js-referenced-users-count').text(users.length);
        } else {
          referencedUsers.hide();
        }
      }
    };

    return MarkdownPreview;
  })();

  markdownPreview = new window.MarkdownPreview();

  previewButtonSelector = '.js-md-preview-button';

  writeButtonSelector = '.js-md-write-button';

  lastTextareaPreviewed = null;

  $.fn.setupMarkdownPreview = function() {
    var $form = $(this);
    $form.find('textarea.markdown-area')
      .on('input', function() {
        markdownPreview.hideReferencedUsers($form);
      })
      .on('blur', function() {
        markdownPreview.showPreview($form);
      });
  };

  $(document).on('markdown-preview:show', function(e, $form) {
    if (!$form) {
      return;
    }
    lastTextareaPreviewed = $form.find('textarea.markdown-area');
    // toggle tabs
    $form.find(writeButtonSelector).parent().removeClass('active');
    $form.find(previewButtonSelector).parent().addClass('active');
    // toggle content
    $form.find('.md-write-holder').hide();
    $form.find('.md-preview-holder').show();
    markdownPreview.showPreview($form);
  });

  $(document).on('markdown-preview:hide', function(e, $form) {
    if (!$form) {
      return;
    }
    lastTextareaPreviewed = null;
    // toggle tabs
    $form.find(writeButtonSelector).parent().addClass('active');
    $form.find(previewButtonSelector).parent().removeClass('active');
    // toggle content
    $form.find('.md-write-holder').show();
    $form.find('textarea.markdown-area').focus();
    $form.find('.md-preview-holder').hide();
  });

  $(document).on('markdown-preview:toggle', function(e, keyboardEvent) {
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

  $(document).on('click', previewButtonSelector, function(e) {
    var $form;
    e.preventDefault();
    $form = $(this).closest('form');
    $(document).triggerHandler('markdown-preview:show', [$form]);
  });

  $(document).on('click', writeButtonSelector, function(e) {
    var $form;
    e.preventDefault();
    $form = $(this).closest('form');
    $(document).triggerHandler('markdown-preview:hide', [$form]);
  });

}).call(this);
