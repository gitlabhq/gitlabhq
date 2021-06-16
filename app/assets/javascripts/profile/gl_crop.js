/* eslint-disable no-useless-escape, no-underscore-dangle, func-names, no-return-assign, consistent-return, class-methods-use-this */

import $ from 'jquery';
import 'cropper';
import { isString } from 'lodash';
import { loadCSSFile } from '../lib/utils/css_utils';

(() => {
  // Matches everything but the file name
  const FILENAMEREGEX = /^.*[\\\/]/;

  class GitLabCrop {
    constructor(
      input,
      {
        filename,
        previewImage,
        modalCrop,
        pickImageEl,
        uploadImageBtn,
        modalCropImg,
        exportWidth = 200,
        exportHeight = 200,
        cropBoxWidth = 200,
        cropBoxHeight = 200,
      } = {},
    ) {
      this.onUploadImageBtnClick = this.onUploadImageBtnClick.bind(this);
      this.onModalHide = this.onModalHide.bind(this);
      this.onModalShow = this.onModalShow.bind(this);
      this.onPickImageClick = this.onPickImageClick.bind(this);
      this.fileInput = $(input);
      this.modalCropImg = isString(this.modalCropImg) ? $(this.modalCropImg) : this.modalCropImg;
      this.fileInput
        .attr('name', `${this.fileInput.attr('name')}-trigger`)
        .attr('id', `${this.fileInput.attr('id')}-trigger`);
      this.exportWidth = exportWidth;
      this.exportHeight = exportHeight;
      this.cropBoxWidth = cropBoxWidth;
      this.cropBoxHeight = cropBoxHeight;
      this.form = this.fileInput.parents('form');
      this.filename = filename;
      this.previewImage = previewImage;
      this.modalCrop = modalCrop;
      this.pickImageEl = pickImageEl;
      this.uploadImageBtn = uploadImageBtn;
      this.modalCropImg = modalCropImg;
      this.filename = this.getElement(filename);
      this.previewImage = this.getElement(previewImage);
      this.pickImageEl = this.getElement(pickImageEl);
      this.modalCrop = isString(modalCrop) ? $(modalCrop) : modalCrop;
      this.uploadImageBtn = isString(uploadImageBtn) ? $(uploadImageBtn) : uploadImageBtn;
      this.modalCropImg = isString(modalCropImg) ? $(modalCropImg) : modalCropImg;
      this.cropActionsBtn = this.modalCrop.find('[data-method]');
      this.bindEvents();
    }

    getElement(selector) {
      return $(selector, this.form);
    }

    bindEvents() {
      const _this = this;
      this.fileInput.on('change', function (e) {
        _this.onFileInputChange(e, this);
        this.value = null;
      });
      this.pickImageEl.on('click', this.onPickImageClick);
      this.modalCrop.on('shown.bs.modal', this.onModalShow);
      this.modalCrop.on('hidden.bs.modal', this.onModalHide);
      this.uploadImageBtn.on('click', this.onUploadImageBtnClick);
      this.cropActionsBtn.on('click', function () {
        const btn = this;
        return _this.onActionBtnClick(btn);
      });
      return (this.croppedImageBlob = null);
    }

    onPickImageClick() {
      return this.fileInput.trigger('click');
    }

    onModalShow() {
      const _this = this;
      return this.modalCropImg.cropper({
        viewMode: 1,
        center: false,
        aspectRatio: 1,
        modal: true,
        scalable: false,
        rotatable: true,
        checkOrientation: true,
        zoomable: true,
        dragMode: 'move',
        guides: false,
        zoomOnTouch: false,
        zoomOnWheel: false,
        cropBoxMovable: false,
        cropBoxResizable: false,
        toggleDragModeOnDblclick: false,
        built() {
          const $image = $(this);
          const container = $image.cropper('getContainerData');
          const { cropBoxWidth, cropBoxHeight } = _this;

          return $image.cropper('setCropBoxData', {
            width: cropBoxWidth,
            height: cropBoxHeight,
            left: (container.width - cropBoxWidth) / 2,
            top: (container.height - cropBoxHeight) / 2,
          });
        },
      });
    }

    onModalHide() {
      this.modalCropImg.attr('src', '').cropper('destroy');
      const modalElement = document.querySelector('.modal-profile-crop');
      if (modalElement) modalElement.remove();
    }

    onUploadImageBtnClick(e) {
      e.preventDefault();
      this.setBlob();
      this.setPreview();
      this.modalCrop.modal('hide');
      return this.fileInput.val('');
    }

    onActionBtnClick(btn) {
      const data = $(btn).data();
      if (this.modalCropImg.data('cropper') && data.method) {
        return this.modalCropImg.cropper(data.method, data.option);
      }
    }

    onFileInputChange(e, input) {
      return this.readFile(input);
    }

    readFile(input) {
      const _this = this;
      const reader = new FileReader();
      reader.onload = () => {
        _this.modalCropImg.attr('src', reader.result);
        return _this.modalCrop.modal('show');
      };
      return reader.readAsDataURL(input.files[0]);
    }

    dataURLtoBlob(dataURL) {
      let i = 0;
      let len = 0;
      const binary = atob(dataURL.split(',')[1]);
      const array = [];

      for (i = 0, len = binary.length; i < len; i += 1) {
        array.push(binary.charCodeAt(i));
      }
      return new Blob([new Uint8Array(array)], {
        type: 'image/png',
      });
    }

    setPreview() {
      const filename = this.fileInput.val().replace(FILENAMEREGEX, '');
      this.previewImage.attr('src', this.dataURL);
      return this.filename.text(filename);
    }

    setBlob() {
      this.dataURL = this.modalCropImg
        .cropper('getCroppedCanvas', {
          width: 200,
          height: 200,
        })
        .toDataURL('image/png');
      return (this.croppedImageBlob = this.dataURLtoBlob(this.dataURL));
    }

    getBlob() {
      return this.croppedImageBlob;
    }
  }

  const cropModal = document.querySelector('.modal-profile-crop');
  if (cropModal) loadCSSFile(cropModal.dataset.cropperCssPath);

  $.fn.glCrop = function (opts) {
    return this.each(function () {
      return $(this).data('glcrop', new GitLabCrop(this, opts));
    });
  };
})(window.gl || (window.gl = {}));
