/* eslint-disable no-useless-escape, max-len, quotes, no-var, no-underscore-dangle, func-names, space-before-function-paren, no-unused-vars, no-return-assign, object-shorthand, one-var, one-var-declaration-per-line, comma-dangle, consistent-return, class-methods-use-this, new-parens */

import $ from 'jquery';
import 'cropper';
import _ from 'underscore';

((global) => {
  // Matches everything but the file name
  const FILENAMEREGEX = /^.*[\\\/]/;

  class GitLabCrop {
    constructor(input, { filename, previewImage, modalCrop, pickImageEl, uploadImageBtn, modalCropImg,
        exportWidth = 200, exportHeight = 200, cropBoxWidth = 200, cropBoxHeight = 200 } = {}) {
      this.onUploadImageBtnClick = this.onUploadImageBtnClick.bind(this);
      this.onModalHide = this.onModalHide.bind(this);
      this.onModalShow = this.onModalShow.bind(this);
      this.onPickImageClick = this.onPickImageClick.bind(this);
      this.fileInput = $(input);
      this.modalCropImg = _.isString(this.modalCropImg) ? $(this.modalCropImg) : this.modalCropImg;
      this.fileInput.attr('name', `${this.fileInput.attr('name')}-trigger`).attr('id', `${this.fileInput.attr('id')}-trigger`);
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
      this.modalCrop = _.isString(modalCrop) ? $(modalCrop) : modalCrop;
      this.uploadImageBtn = _.isString(uploadImageBtn) ? $(uploadImageBtn) : uploadImageBtn;
      this.modalCropImg = _.isString(modalCropImg) ? $(modalCropImg) : modalCropImg;
      this.cropActionsBtn = this.modalCrop.find('[data-method]');
      this.bindEvents();
    }

    getElement(selector) {
      return $(selector, this.form);
    }

    bindEvents() {
      var _this;
      _this = this;
      this.fileInput.on('change', function(e) {
        return _this.onFileInputChange(e, this);
      });
      this.pickImageEl.on('click', this.onPickImageClick);
      this.modalCrop.on('shown.bs.modal', this.onModalShow);
      this.modalCrop.on('hidden.bs.modal', this.onModalHide);
      this.uploadImageBtn.on('click', this.onUploadImageBtnClick);
      this.cropActionsBtn.on('click', function(e) {
        var btn;
        btn = this;
        return _this.onActionBtnClick(btn);
      });
      return this.croppedImageBlob = null;
    }

    onPickImageClick() {
      return this.fileInput.trigger('click');
    }

    onModalShow() {
      var _this;
      _this = this;
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
        built: function() {
          var $image, container, cropBoxHeight, cropBoxWidth;
          $image = $(this);
          container = $image.cropper('getContainerData');
          cropBoxWidth = _this.cropBoxWidth;
          cropBoxHeight = _this.cropBoxHeight;
          return $image.cropper('setCropBoxData', {
            width: cropBoxWidth,
            height: cropBoxHeight,
            left: (container.width - cropBoxWidth) / 2,
            top: (container.height - cropBoxHeight) / 2
          });
        }
      });
    }

    onModalHide() {
      return this.modalCropImg.attr('src', '').cropper('destroy');
    }

    onUploadImageBtnClick(e) {
      e.preventDefault();
      this.setBlob();
      this.setPreview();
      this.modalCrop.modal('hide');
      return this.fileInput.val('');
    }

    onActionBtnClick(btn) {
      var data, result;
      data = $(btn).data();
      if (this.modalCropImg.data('cropper') && data.method) {
        return result = this.modalCropImg.cropper(data.method, data.option);
      }
    }

    onFileInputChange(e, input) {
      return this.readFile(input);
    }

    readFile(input) {
      var _this, reader;
      _this = this;
      reader = new FileReader;
      reader.onload = () => {
        _this.modalCropImg.attr('src', reader.result);
        return _this.modalCrop.modal('show');
      };
      return reader.readAsDataURL(input.files[0]);
    }

    dataURLtoBlob(dataURL) {
      var array, binary, i, k, len, v;
      binary = atob(dataURL.split(',')[1]);
      array = [];
      for (k = i = 0, len = binary.length; i < len; k = (i += 1)) {
        v = binary[k];
        array.push(binary.charCodeAt(k));
      }
      return new Blob([new Uint8Array(array)], {
        type: 'image/png'
      });
    }

    setPreview() {
      var filename;
      this.previewImage.attr('src', this.dataURL);
      filename = this.fileInput.val().replace(FILENAMEREGEX, '');
      return this.filename.text(filename);
    }

    setBlob() {
      this.dataURL = this.modalCropImg.cropper('getCroppedCanvas', {
        width: 200,
        height: 200
      }).toDataURL('image/png');
      return this.croppedImageBlob = this.dataURLtoBlob(this.dataURL);
    }

    getBlob() {
      return this.croppedImageBlob;
    }
  }

  $.fn.glCrop = function(opts) {
    return this.each(function() {
      return $(this).data('glcrop', new GitLabCrop(this, opts));
    });
  };
})(window.gl || (window.gl = {}));
