(function() {
  var lastTextareaPreviewed, markdownPreview, previewButtonSelector, writeButtonSelector;

  this.MarkdownPreview = (function() {
    function MarkdownPreview() {}

    MarkdownPreview.prototype.referenceThreshold = 10;

    MarkdownPreview.prototype.ajaxCache = {};

    MarkdownPreview.prototype.showPreview = function(form) {
      var mdText, preview;
      preview = form.find('.js-md-preview');
      mdText = form.find('textarea.markdown-area').val();
      if (mdText.trim().length === 0) {
        preview.text('Nothing to preview.');
        return this.hideReferencedUsers(form);
      } else {
        preview.text('Loading...');
        return this.renderMarkdown(mdText, (function(_this) {
          return function(response) {
            preview.html(response.body);
            preview.syntaxHighlight();
            return _this.renderReferencedUsers(response.references.users, form);
          };
        })(this));
      }
    };

    MarkdownPreview.prototype.renderMarkdown = function(text, success) {
      if (!window.preview_markdown_path) {
        return;
      }
      if (text === this.ajaxCache.text) {
        return success(this.ajaxCache.response);
      }
      return $.ajax({
        type: 'POST',
        url: window.preview_markdown_path,
        data: {
          text: text
        },
        dataType: 'json',
        success: (function(_this) {
          return function(response) {
            _this.ajaxCache = {
              text: text,
              response: response
            };
            return success(response);
          };
        })(this)
      });
    };

    MarkdownPreview.prototype.hideReferencedUsers = function(form) {
      var referencedUsers;
      referencedUsers = form.find('.referenced-users');
      return referencedUsers.hide();
    };

    MarkdownPreview.prototype.renderReferencedUsers = function(users, form) {
      var referencedUsers;
      referencedUsers = form.find('.referenced-users');
      if (referencedUsers.length) {
        if (users.length >= this.referenceThreshold) {
          referencedUsers.show();
          return referencedUsers.find('.js-referenced-users-count').text(users.length);
        } else {
          return referencedUsers.hide();
        }
      }
    };

    return MarkdownPreview;

  })();

  markdownPreview = new MarkdownPreview();

  previewButtonSelector = '.js-md-preview-button';

  writeButtonSelector = '.js-md-write-button';

  lastTextareaPreviewed = null;

  $.fn.setupMarkdownPreview = function() {
    var $form, form_textarea;
    $form = $(this);
    form_textarea = $form.find('textarea.markdown-area');
    form_textarea.on('input', function() {
      return markdownPreview.hideReferencedUsers($form);
    });
    return form_textarea.on('blur', function() {
      return markdownPreview.showPreview($form);
    });
  };

  $(document).on('markdown-preview:show', function(e, $form) {
    if (!$form) {
      return;
    }
    lastTextareaPreviewed = $form.find('textarea.markdown-area');
    $form.find(writeButtonSelector).parent().removeClass('active');
    $form.find(previewButtonSelector).parent().addClass('active');
    $form.find('.md-write-holder').hide();
    $form.find('.md-preview-holder').show();
    return markdownPreview.showPreview($form);
  });

  $(document).on('markdown-preview:hide', function(e, $form) {
    if (!$form) {
      return;
    }
    lastTextareaPreviewed = null;
    $form.find(writeButtonSelector).parent().addClass('active');
    $form.find(previewButtonSelector).parent().removeClass('active');
    $form.find('.md-write-holder').show();
    $form.find('textarea.markdown-area').focus();
    return $form.find('.md-preview-holder').hide();
  });

  $(document).on('markdown-preview:toggle', function(e, keyboardEvent) {
    var $target;
    $target = $(keyboardEvent.target);
    if ($target.is('textarea.markdown-area')) {
      $(document).triggerHandler('markdown-preview:show', [$target.closest('form')]);
      return keyboardEvent.preventDefault();
    } else if (lastTextareaPreviewed) {
      $target = lastTextareaPreviewed;
      $(document).triggerHandler('markdown-preview:hide', [$target.closest('form')]);
      return keyboardEvent.preventDefault();
    }
  });

  $(document).on('click', previewButtonSelector, function(e) {
    var $form;
    e.preventDefault();
    $form = $(this).closest('form');
    return $(document).triggerHandler('markdown-preview:show', [$form]);
  });

  $(document).on('click', writeButtonSelector, function(e) {
    var $form;
    e.preventDefault();
    $form = $(this).closest('form');
    return $(document).triggerHandler('markdown-preview:hide', [$form]);
  });

}).call(this);
