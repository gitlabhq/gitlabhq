
/*= require preview_markdown */

(function() {
  this.DropzoneInput = (function() {
    function DropzoneInput(form) {
      var $mdArea, alertAttr, alertClass, appendToTextArea, btnAlert, child, closeAlertMessage, closeSpinner, divAlert, divHover, divSpinner, dropzone, form_dropzone, form_textarea, getFilename, handlePaste, iconPaperclip, iconSpinner, insertToTextArea, isImage, max_file_size, pasteText, project_uploads_path, showError, showSpinner, uploadFile, uploadProgress;
      Dropzone.autoDiscover = false;
      alertClass = "alert alert-danger alert-dismissable div-dropzone-alert";
      alertAttr = "class=\"close\" data-dismiss=\"alert\"" + "aria-hidden=\"true\"";
      divHover = "<div class=\"div-dropzone-hover\"></div>";
      divSpinner = "<div class=\"div-dropzone-spinner\"></div>";
      divAlert = "<div class=\"" + alertClass + "\"></div>";
      iconPaperclip = "<i class=\"fa fa-paperclip div-dropzone-icon\"></i>";
      iconSpinner = "<i class=\"fa fa-spinner fa-spin div-dropzone-icon\"></i>";
      uploadProgress = $("<div class=\"div-dropzone-progress\"></div>");
      btnAlert = "<button type=\"button\"" + alertAttr + ">&times;</button>";
      project_uploads_path = window.project_uploads_path || null;
      max_file_size = gon.max_file_size || 10;
      form_textarea = $(form).find(".js-gfm-input");
      form_textarea.wrap("<div class=\"div-dropzone\"></div>");
      form_textarea.on('paste', (function(_this) {
        return function(event) {
          return handlePaste(event);
        };
      })(this));
      $mdArea = $(form_textarea).closest('.md-area');
      $(form).setupMarkdownPreview();
      form_dropzone = $(form).find('.div-dropzone');
      form_dropzone.parent().addClass("div-dropzone-wrapper");
      form_dropzone.append(divHover);
      form_dropzone.find(".div-dropzone-hover").append(iconPaperclip);
      form_dropzone.append(divSpinner);
      form_dropzone.find(".div-dropzone-spinner").append(iconSpinner);
      form_dropzone.find(".div-dropzone-spinner").append(uploadProgress);
      form_dropzone.find(".div-dropzone-spinner").css({
        "opacity": 0,
        "display": "none"
      });
      dropzone = form_dropzone.dropzone({
        url: project_uploads_path,
        dictDefaultMessage: "",
        clickable: true,
        paramName: "file",
        maxFilesize: max_file_size,
        uploadMultiple: false,
        headers: {
          "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")
        },
        previewContainer: false,
        processing: function() {
          return $(".div-dropzone-alert").alert("close");
        },
        dragover: function() {
          $mdArea.addClass('is-dropzone-hover');
          form.find(".div-dropzone-hover").css("opacity", 0.7);
        },
        dragleave: function() {
          $mdArea.removeClass('is-dropzone-hover');
          form.find(".div-dropzone-hover").css("opacity", 0);
        },
        drop: function() {
          $mdArea.removeClass('is-dropzone-hover');
          form.find(".div-dropzone-hover").css("opacity", 0);
          form_textarea.focus();
        },
        success: function(header, response) {
          pasteText(response.link.markdown);
        },
        error: function(temp) {
          var checkIfMsgExists, errorAlert;
          errorAlert = $(form).find('.error-alert');
          checkIfMsgExists = errorAlert.children().length;
          if (checkIfMsgExists === 0) {
            errorAlert.append(divAlert);
            $(".div-dropzone-alert").append(btnAlert + "Attaching the file failed.");
          }
        },
        totaluploadprogress: function(totalUploadProgress) {
          uploadProgress.text(Math.round(totalUploadProgress) + "%");
        },
        sending: function() {
          form_dropzone.find(".div-dropzone-spinner").css({
            "opacity": 0.7,
            "display": "inherit"
          });
        },
        queuecomplete: function() {
          uploadProgress.text("");
          $(".dz-preview").remove();
          $(".markdown-area").trigger("input");
          $(".div-dropzone-spinner").css({
            "opacity": 0,
            "display": "none"
          });
        }
      });
      child = $(dropzone[0]).children("textarea");
      handlePaste = function(event) {
        var filename, image, pasteEvent, text;
        pasteEvent = event.originalEvent;
        if (pasteEvent.clipboardData && pasteEvent.clipboardData.items) {
          image = isImage(pasteEvent);
          if (image) {
            event.preventDefault();
            filename = getFilename(pasteEvent) || "image.png";
            text = "{{" + filename + "}}";
            pasteText(text);
            return uploadFile(image.getAsFile(), filename);
          }
        }
      };
      isImage = function(data) {
        var i, item;
        i = 0;
        while (i < data.clipboardData.items.length) {
          item = data.clipboardData.items[i];
          if (item.type.indexOf("image") !== -1) {
            return item;
          }
          i++;
        }
        return false;
      };
      pasteText = function(text) {
        var afterSelection, beforeSelection, caretEnd, caretStart, textEnd;
        caretStart = $(child)[0].selectionStart;
        caretEnd = $(child)[0].selectionEnd;
        textEnd = $(child).val().length;
        beforeSelection = $(child).val().substring(0, caretStart);
        afterSelection = $(child).val().substring(caretEnd, textEnd);
        $(child).val(beforeSelection + text + afterSelection);
        child.get(0).setSelectionRange(caretStart + text.length, caretEnd + text.length);
        return form_textarea.trigger("input");
      };
      getFilename = function(e) {
        var value;
        if (window.clipboardData && window.clipboardData.getData) {
          value = window.clipboardData.getData("Text");
        } else if (e.clipboardData && e.clipboardData.getData) {
          value = e.clipboardData.getData("text/plain");
        }
        value = value.split("\r");
        return value.first();
      };
      uploadFile = function(item, filename) {
        var formData;
        formData = new FormData();
        formData.append("file", item, filename);
        return $.ajax({
          url: project_uploads_path,
          type: "POST",
          data: formData,
          dataType: "json",
          processData: false,
          contentType: false,
          headers: {
            "X-CSRF-Token": $("meta[name=\"csrf-token\"]").attr("content")
          },
          beforeSend: function() {
            showSpinner();
            return closeAlertMessage();
          },
          success: function(e, textStatus, response) {
            return insertToTextArea(filename, response.responseJSON.link.markdown);
          },
          error: function(response) {
            return showError(response.responseJSON.message);
          },
          complete: function() {
            return closeSpinner();
          }
        });
      };
      insertToTextArea = function(filename, url) {
        return $(child).val(function(index, val) {
          return val.replace("{{" + filename + "}}", url + "\n");
        });
      };
      appendToTextArea = function(url) {
        return $(child).val(function(index, val) {
          return val + url + "\n";
        });
      };
      showSpinner = function(e) {
        return form.find(".div-dropzone-spinner").css({
          "opacity": 0.7,
          "display": "inherit"
        });
      };
      closeSpinner = function() {
        return form.find(".div-dropzone-spinner").css({
          "opacity": 0,
          "display": "none"
        });
      };
      showError = function(message) {
        var checkIfMsgExists, errorAlert;
        errorAlert = $(form).find('.error-alert');
        checkIfMsgExists = errorAlert.children().length;
        if (checkIfMsgExists === 0) {
          errorAlert.append(divAlert);
          return $(".div-dropzone-alert").append(btnAlert + message);
        }
      };
      closeAlertMessage = function() {
        return form.find(".div-dropzone-alert").alert("close");
      };
      form.find(".markdown-selector").click(function(e) {
        e.preventDefault();
        $(this).closest('.gfm-form').find('.div-dropzone').click();
      });
    }

    return DropzoneInput;

  })();

}).call(this);
