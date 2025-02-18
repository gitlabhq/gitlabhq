import Dropzone from 'dropzone';
import $ from 'jquery';
import { escape } from 'lodash';
import './behaviors/preview_markdown';
import { spriteIcon, insertText } from '~/lib/utils/common_utils';
import { getFilename } from '~/lib/utils/file_upload';
import { truncate } from '~/lib/utils/text_utility';
import { n__, __ } from '~/locale';
import { getRetinaDimensions } from '~/lib/utils/image_utils';
import PasteMarkdownTable from './behaviors/markdown/paste_markdown_table';
import axios from './lib/utils/axios_utils';
import csrf from './lib/utils/csrf';

Dropzone.autoDiscover = false;

/**
 * Return the error message string from the given response.
 *
 * @param {String|Object} res
 */
function getErrorMessage(res) {
  if (!res || typeof res === 'string') {
    return res;
  }

  return res.message;
}

export default function dropzoneInput(form, config = { parallelUploads: 2 }) {
  const divHover = '<div class="div-dropzone-hover"></div>';
  const iconPaperclip = spriteIcon('paperclip', 'div-dropzone-icon s24');
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
  let uploadFile;
  let hasPlainText;

  formTextarea.wrap('<div class="div-dropzone"></div>');

  // Add dropzone area to the form.
  const $mdArea = formTextarea.closest('.md-area');
  const $formDropzone = form.find('.div-dropzone');
  $formDropzone.parent().addClass('div-dropzone-wrapper');
  $formDropzone.append(divHover);
  $formDropzone.find('.div-dropzone-hover').append(iconPaperclip);

  if (!uploadsPath) {
    $formDropzone.addClass('js-invalid-dropzone');
    return null;
  }

  formTextarea.on('paste', (event) => handlePaste(event));

  const dropzone = $formDropzone.dropzone({
    url: uploadsPath,
    dictDefaultMessage: '',
    clickable: form.get(0).querySelector('[data-button-type="attach-file"]') ?? true,
    paramName: 'file',
    maxFilesize: maxFileSize,
    uploadMultiple: false,
    headers: csrf.headers,
    previewContainer: false,
    ...config,
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

      addFileToForm(response.link.url, header.size);
      pasteText(response.link.markdown, shouldPad);
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
      $uploadingErrorContainer.addClass('hide');
      $uploadingProgressContainer.removeClass('hide');
      $cancelButton.removeClass('hide');
    },
    removedfile: () => {
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
  $cancelButton.on('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    Dropzone.forElement($formDropzone.get(0)).removeAllFiles(true);
  });

  // If 'error' event is fired, we store a failed files,
  // clear dropzone files queue, change status of failed files to undefined,
  // and add that files to the dropzone files queue again.
  // addFile() adds file to dropzone files queue and upload it.
  $retryLink.on('click', (e) => {
    const dropzoneInstance = Dropzone.forElement(
      e.target.closest('.js-main-target-form').querySelector('.div-dropzone'),
    );
    const failedFiles = dropzoneInstance.files;

    e.preventDefault();

    // 'true' parameter of removeAllFiles() cancels
    // uploading of files that are being uploaded at the moment.
    dropzoneInstance.removeAllFiles(true);

    failedFiles.map((failedFile) => {
      const file = failedFile;

      if (file.status === Dropzone.ERROR) {
        file.status = undefined;
        file.accepted = undefined;
      }

      return dropzoneInstance.addFile(file);
    });
  });

  handlePaste = (event) => {
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
      } else if (!hasPlainText(pasteEvent)) {
        const fileList = [...clipboardData.files];
        fileList.forEach((file) => {
          if (file.type.indexOf('image') !== -1) {
            event.preventDefault();
            const MAX_FILE_NAME_LENGTH = 246;

            const filename = getFilename(file) || 'image.png';
            const truncateFilename = truncate(filename, MAX_FILE_NAME_LENGTH);
            const text = `{{${truncateFilename}}}`;
            pasteText(text);

            uploadFile(file, truncateFilename);
          }
        });
      }
    }
  };

  hasPlainText = (data) => {
    const clipboardDataList = [...data.clipboardData.items];
    return clipboardDataList.some((item) => item.type === 'text/plain');
  };

  pasteText = (text, shouldPad) => {
    let formattedText = text;
    if (shouldPad) {
      formattedText += '\n\n';
    }
    const textarea = child.get(0);
    insertText(textarea, formattedText);
    formTextarea.get(0).dispatchEvent(new Event('input'));
    formTextarea.trigger('input');
  };

  addFileToForm = (path) => {
    $(form).append(`<input type="hidden" name="files[]" value="${escape(path)}">`);
  };

  const showSpinner = () => $uploadingProgressContainer.removeClass('hide');

  const closeSpinner = () => $uploadingProgressContainer.addClass('hide');

  const showError = (message) => {
    $uploadingErrorContainer.removeClass('hide');
    $uploadingErrorMessage.html(message);
  };

  const insertToTextArea = (filename, url) => {
    const $child = $(child);
    const textarea = $child.get(0);
    const formattedText = `{{${filename}}}`;

    const replaceStart = textarea.value.indexOf(formattedText);
    if (replaceStart !== -1) {
      const replaceEnd = replaceStart + formattedText.length;
      textarea.setSelectionRange(replaceStart, replaceEnd);
    }
    insertText(textarea, url);
    $child.trigger('change');
  };

  uploadFile = (item, filename) => {
    const formData = new FormData();
    formData.append('file', item, filename);

    showSpinner();

    axios
      .post(uploadsPath, formData)
      .then(async ({ data }) => {
        let md = data.link.markdown;

        const { width, height } = (await getRetinaDimensions(item)) || {};
        if (width && height) {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          md += `{width=${width} height=${height}}`;
        }
        insertToTextArea(filename, md);
        closeSpinner();
      })
      .catch((e) => {
        showError(e.response.data.message);
        closeSpinner();
      });
  };

  updateAttachingMessage = (files, messageContainer) => {
    const filesCount = files.filter(
      (file) => file.status === 'uploading' || file.status === 'queued',
    ).length;
    const attachingMessage = n__('Attaching a file', 'Attaching %d files', filesCount);

    messageContainer.text(`${attachingMessage} -`);
  };

  function handleAttachFile(e) {
    e.preventDefault();
    $(this).closest('.gfm-form').find('.div-dropzone').click();
    formTextarea.focus();
  }

  form.find('.markdown-selector').click(handleAttachFile);

  const $attachFileButton = form.find('.js-attach-file-button');
  if ($attachFileButton.length) {
    $attachFileButton.get(0).addEventListener('click', handleAttachFile);
  }

  return $formDropzone.get(0) ? Dropzone.forElement($formDropzone.get(0)) : null;
}
