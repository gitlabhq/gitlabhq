import $ from 'jquery';
import Dropzone from 'dropzone';
import _ from 'underscore';
import './behaviors/preview_markdown';
import PasteMarkdownTable from './behaviors/markdown/paste_markdown_table';
import csrf from './lib/utils/csrf';
import axios from './lib/utils/axios_utils';
import { n__, __ } from '~/locale';

Dropzone.autoDiscover = false;

/**
 * Return the error message string from the given response.
 *
 * @param {String|Object} res
 */
function getErrorMessage(res) {
  if (!res || _.isString(res)) {
    return res;
  }

  return res.message;
}

export default function dropzoneInput(form) {
  const divHover = '<div class="div-dropzone-hover"></div>';
  const iconPaperclip = '<i class="fa fa-paperclip div-dropzone-icon"></i>';
  const $attachButton = form.find('.button-attach-file');
  const $attachingFileMessage = form.find('.attaching-file-message');
  const $cancelButton = form.find('.button-cancel-uploading-files');
  const $retryLink = form.find('.retry-uploading-link');
  const $uploadProgress = form.find('.uploading-progress');
  const $uploadingErrorContainer = form.find('.uploading-error-container');
  const $uploadingErrorMessage = form.find('.uploading-error-message');
  const $uploadingProgressContainer = form.find('.uploading-progress-container');
  const uploadsPath = form.data('uploads-path') || window.uploads_path || null;
  const maxFileSize = gon.max_file_size || 10;
  const formTextarea = form.find('.js-gfm-input');
  let handlePaste;
  let pasteText;
  let addFileToForm;
  let updateAttachingMessage;
  let isImage;
  let getFilename;
  let uploadFile;

  formTextarea.wrap('<div class="div-dropzone"></div>');
  formTextarea.on('paste', event => handlePaste(event));

  // Add dropzone area to the form.
  const $mdArea = formTextarea.closest('.md-area');
  form.setupMarkdownPreview();
  const $formDropzone = form.find('.div-dropzone');
  $formDropzone.parent().addClass('div-dropzone-wrapper');
  $formDropzone.append(divHover);
  $formDropzone.find('.div-dropzone-hover').append(iconPaperclip);

  if (!uploadsPath) {
    $formDropzone.addClass('js-invalid-dropzone');
    return null;
  }

  const dropzone = $formDropzone.dropzone({
    url: uploadsPath,
    dictDefaultMessage: '',
    clickable: true,
    paramName: 'file',
    maxFilesize: maxFileSize,
    uploadMultiple: false,
    headers: csrf.headers,
    previewContainer: false,
    processing: () => $('.div-dropzone-alert').alert('close'),
    dragover: () => {
      $mdArea.addClass('is-dropzone-hover');
      form.find('.div-dropzone-hover').css('opacity', 0.7);
    },
    dragleave: () => {
      $mdArea.removeClass('is-dropzone-hover');
      form.find('.div-dropzone-hover').css('opacity', 0);
    },
    drop: () => {
      $mdArea.removeClass('is-dropzone-hover');
      form.find('.div-dropzone-hover').css('opacity', 0);
      formTextarea.focus();
    },
    success(header, response) {
      const processingFileCount = this.getQueuedFiles().length + this.getUploadingFiles().length;
      const shouldPad = processingFileCount >= 1;

      pasteText(response.link.markdown, shouldPad);
      // Show 'Attach a file' link only when all files have been uploaded.
      if (!processingFileCount) $attachButton.removeClass('hide');
      addFileToForm(response.link.url);
    },
    error: (file, errorMessage = __('Attaching the file failed.'), xhr) => {
      // If 'error' event is fired by dropzone, the second parameter is error message.
      // If the 'errorMessage' parameter is empty, the default error message is set.
      // If the 'error' event is fired by backend (xhr) error response, the third parameter is
      // xhr object (xhr.responseText is error message).
      // On error we hide the 'Attach' and 'Cancel' buttons
      // and show an error.
      const message = getErrorMessage(errorMessage || xhr.responseText);

      $uploadingErrorContainer.removeClass('hide');
      $uploadingErrorMessage.html(message);
      $attachButton.addClass('hide');
      $cancelButton.addClass('hide');
    },
    totaluploadprogress(totalUploadProgress) {
      updateAttachingMessage(this.files, $attachingFileMessage);
      $uploadProgress.text(`${Math.round(totalUploadProgress)}%`);
    },
    sending: () => {
      // DOM elements already exist.
      // Instead of dynamically generating them,
      // we just either hide or show them.
      $attachButton.addClass('hide');
      $uploadingErrorContainer.addClass('hide');
      $uploadingProgressContainer.removeClass('hide');
      $cancelButton.removeClass('hide');
    },
    removedfile: () => {
      $attachButton.removeClass('hide');
      $cancelButton.addClass('hide');
      $uploadingProgressContainer.addClass('hide');
      $uploadingErrorContainer.addClass('hide');
    },
    queuecomplete: () => {
      $('.dz-preview').remove();
      $('.markdown-area').trigger('input');

      $uploadingProgressContainer.addClass('hide');
      $cancelButton.addClass('hide');
    },
  });

  const child = $(dropzone[0]).children('textarea');

  // removeAllFiles(true) stops uploading files (if any)
  // and remove them from dropzone files queue.
  $cancelButton.on('click', e => {
    e.preventDefault();
    e.stopPropagation();
    Dropzone.forElement($formDropzone.get(0)).removeAllFiles(true);
  });

  // If 'error' event is fired, we store a failed files,
  // clear dropzone files queue, change status of failed files to undefined,
  // and add that files to the dropzone files queue again.
  // addFile() adds file to dropzone files queue and upload it.
  $retryLink.on('click', e => {
    const dropzoneInstance = Dropzone.forElement(
      e.target.closest('.js-main-target-form').querySelector('.div-dropzone'),
    );
    const failedFiles = dropzoneInstance.files;

    e.preventDefault();

    // 'true' parameter of removeAllFiles() cancels
    // uploading of files that are being uploaded at the moment.
    dropzoneInstance.removeAllFiles(true);

    failedFiles.map(failedFile => {
      const file = failedFile;

      if (file.status === Dropzone.ERROR) {
        file.status = undefined;
        file.accepted = undefined;
      }

      return dropzoneInstance.addFile(file);
    });
  });
  // eslint-disable-next-line consistent-return
  handlePaste = event => {
    const pasteEvent = event.originalEvent;
    const { clipboardData } = pasteEvent;
    if (clipboardData && clipboardData.items) {
      const converter = new PasteMarkdownTable(clipboardData);
      // Apple Numbers copies a table as an image, HTML, and text, so
      // we need to check for the presence of a table first.
      if (converter.isTable()) {
        event.preventDefault();
        const text = converter.convertToTableMarkdown();
        pasteText(text);
      } else {
        const image = isImage(pasteEvent);

        if (image) {
          event.preventDefault();
          const filename = getFilename(pasteEvent) || 'image.png';
          const text = `{{${filename}}}`;
          pasteText(text);
          return uploadFile(image.getAsFile(), filename);
        }
      }
    }
  };

  isImage = data => {
    let i = 0;
    while (i < data.clipboardData.items.length) {
      const item = data.clipboardData.items[i];
      if (item.type.indexOf('image') !== -1) {
        return item;
      }
      i += 1;
    }
    return false;
  };

  pasteText = (text, shouldPad) => {
    let formattedText = text;
    if (shouldPad) {
      formattedText += '\n\n';
    }
    const textarea = child.get(0);
    const caretStart = textarea.selectionStart;
    const caretEnd = textarea.selectionEnd;
    const textEnd = $(child).val().length;
    const beforeSelection = $(child)
      .val()
      .substring(0, caretStart);
    const afterSelection = $(child)
      .val()
      .substring(caretEnd, textEnd);
    $(child).val(beforeSelection + formattedText + afterSelection);
    textarea.setSelectionRange(caretStart + formattedText.length, caretEnd + formattedText.length);
    textarea.style.height = `${textarea.scrollHeight}px`;
    formTextarea.get(0).dispatchEvent(new Event('input'));
    return formTextarea.trigger('input');
  };

  addFileToForm = path => {
    $(form).append(`<input type="hidden" name="files[]" value="${_.escape(path)}">`);
  };

  getFilename = e => {
    let value;
    if (window.clipboardData && window.clipboardData.getData) {
      value = window.clipboardData.getData('Text');
    } else if (e.clipboardData && e.clipboardData.getData) {
      value = e.clipboardData.getData('text/plain');
    }
    value = value.split('\r');
    return value[0];
  };

  const showSpinner = () => $uploadingProgressContainer.removeClass('hide');

  const closeSpinner = () => $uploadingProgressContainer.addClass('hide');

  const showError = message => {
    $uploadingErrorContainer.removeClass('hide');
    $uploadingErrorMessage.html(message);
  };

  const closeAlertMessage = () => form.find('.div-dropzone-alert').alert('close');

  const insertToTextArea = (filename, url) => {
    const $child = $(child);
    $child.val((index, val) => val.replace(`{{${filename}}}`, url));

    $child.trigger('change');
  };

  uploadFile = (item, filename) => {
    const formData = new FormData();
    formData.append('file', item, filename);

    showSpinner();
    closeAlertMessage();

    axios
      .post(uploadsPath, formData)
      .then(({ data }) => {
        const md = data.link.markdown;

        insertToTextArea(filename, md);
        closeSpinner();
      })
      .catch(e => {
        showError(e.response.data.message);
        closeSpinner();
      });
  };

  updateAttachingMessage = (files, messageContainer) => {
    const filesCount = files.filter(file => file.status === 'uploading' || file.status === 'queued')
      .length;
    const attachingMessage = n__('Attaching a file', 'Attaching %d files', filesCount);

    messageContainer.text(`${attachingMessage} -`);
  };

  form.find('.markdown-selector').click(function onMarkdownClick(e) {
    e.preventDefault();
    $(this)
      .closest('.gfm-form')
      .find('.div-dropzone')
      .click();
    formTextarea.focus();
  });

  return $formDropzone.get(0) ? Dropzone.forElement($formDropzone.get(0)) : null;
}
