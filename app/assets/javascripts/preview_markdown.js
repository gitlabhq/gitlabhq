/* eslint-disable func-names, no-var, object-shorthand, comma-dangle, prefer-arrow-callback */

// MarkdownPreview
//
// Handles toggling the "Write" and "Preview" tab clicks, rendering the preview,
// and showing a warning when more than `x` users are referenced.
//
(function () {
  var lastTextareaPreviewed;
  var markdownPreview;
  var previewButtonSelector;
  var writeButtonSelector;
  var $document;

  window.MarkdownPreview = (function () {
    function MarkdownPreview() {}

    // Minimum number of users referenced before triggering a warning
    MarkdownPreview.prototype.referenceThreshold = 10;

    MarkdownPreview.prototype.ajaxCache = {};

    MarkdownPreview.prototype.showPreview = function ($form) {
      var mdText;
      var preview = $form.find('.js-md-preview');
      if (preview.hasClass('md-preview-loading')) {
        return;
      }
      mdText = $form.find('textarea.markdown-area').val();

      if (mdText.trim().length === 0) {
        preview.text('Nothing to preview.');
        this.hideReferencedUsers($form);
      } else {
        preview.addClass('md-preview-loading').text('Loading...');
        this.fetchMarkdownPreview(mdText, (function (response) {
          preview.removeClass('md-preview-loading').html(response.body);
          preview.renderGFM();
          this.renderReferencedUsers(response.references.users, $form);
        }).bind(this));
      }
    };

    MarkdownPreview.prototype.fetchMarkdownPreview = function (text, success) {
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
        success: (function (response) {
          this.ajaxCache = {
            text: text,
            response: response
          };
          success(response);
        }).bind(this)
      });
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

    return MarkdownPreview;
  }());

  markdownPreview = new window.MarkdownPreview();

  previewButtonSelector = '.js-md-preview-button';

  writeButtonSelector = '.js-md-write-button';

  lastTextareaPreviewed = null;

  $.fn.setupMarkdownPreview = function () {
    var $form = $(this);
    $form.find('textarea.markdown-area').off('input.hideReferencedUsers')
      .on('input.hideReferencedUsers', function () {
        markdownPreview.hideReferencedUsers($form);
      });
  };

  $document = $(document);

  $document.off('markdown-preview:show.showPreview')
    .on('markdown-preview:show.showPreview', function (e, $form) {
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

  $document.off('markdown-preview:hide.hidePreview')
    .on('markdown-preview:hide.hidePreview', function (e, $form) {
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

  $document.off('markdown-preview:toggle.togglePreview')
    .on('markdown-preview:toggle.togglePreview', function (e, keyboardEvent) {
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

  $document.off('click.triggerPreviewShow')
    .on('click.triggerPreviewShow', previewButtonSelector, function (e) {
      var $form;
      e.preventDefault();
      $form = $(this).closest('form');
      $(document).triggerHandler('markdown-preview:show', [$form]);
    });

  $document.off('click.triggerPreviewHide')
    .on('click.triggerPreviewHide', writeButtonSelector, function (e) {
      var $form;
      e.preventDefault();
      $form = $(this).closest('form');
      $(document).triggerHandler('markdown-preview:hide', [$form]);
    });
}());
