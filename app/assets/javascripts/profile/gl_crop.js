(function() {
  var GitLabCrop,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  GitLabCrop = (function() {
    var FILENAMEREGEX;

    // Matches everything but the file name
    FILENAMEREGEX = /^.*[\\\/]/;

    function GitLabCrop(input, opts) {
      var ref, ref1, ref2, ref3, ref4;
      if (opts == null) {
        opts = {};
      }
      this.onUploadImageBtnClick = bind(this.onUploadImageBtnClick, this);
      this.onModalHide = bind(this.onModalHide, this);
      this.onModalShow = bind(this.onModalShow, this);
      this.onPickImageClick = bind(this.onPickImageClick, this);
      this.fileInput = $(input);
      // We should rename to avoid spec to fail
      // Form will submit the proper input filed with a file using FormData
      this.fileInput.attr('name', (this.fileInput.attr('name')) + "-trigger").attr('id', (this.fileInput.attr('id')) + "-trigger");
      // Set defaults
      this.exportWidth = (ref = opts.exportWidth) != null ? ref : 200, this.exportHeight = (ref1 = opts.exportHeight) != null ? ref1 : 200, this.cropBoxWidth = (ref2 = opts.cropBoxWidth) != null ? ref2 : 200, this.cropBoxHeight = (ref3 = opts.cropBoxHeight) != null ? ref3 : 200, this.form = (ref4 = opts.form) != null ? ref4 : this.fileInput.parents('form'), this.filename = opts.filename, this.previewImage = opts.previewImage, this.modalCrop = opts.modalCrop, this.pickImageEl = opts.pickImageEl, this.uploadImageBtn = opts.uploadImageBtn, this.modalCropImg = opts.modalCropImg;
      // Required params
      // Ensure needed elements are jquery objects
      // If selector is provided we will convert them to a jQuery Object
      this.filename = this.getElement(this.filename);
      this.previewImage = this.getElement(this.previewImage);
      this.pickImageEl = this.getElement(this.pickImageEl);
      // Modal elements usually are outside the @form element
      this.modalCrop = _.isString(this.modalCrop) ? $(this.modalCrop) : this.modalCrop;
      this.uploadImageBtn = _.isString(this.uploadImageBtn) ? $(this.uploadImageBtn) : this.uploadImageBtn;
      this.modalCropImg = _.isString(this.modalCropImg) ? $(this.modalCropImg) : this.modalCropImg;
      this.cropActionsBtn = this.modalCrop.find('[data-method]');
      this.bindEvents();
    }

    GitLabCrop.prototype.getElement = function(selector) {
      return $(selector, this.form);
    };

    GitLabCrop.prototype.bindEvents = function() {
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
    };

    GitLabCrop.prototype.onPickImageClick = function() {
      return this.fileInput.trigger('click');
    };

    GitLabCrop.prototype.onModalShow = function() {
      var _this;
      _this = this;
      return this.modalCropImg.cropper({
        viewMode: 1,
        center: false,
        aspectRatio: 1,
        modal: true,
        scalable: false,
        rotatable: false,
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
    };

    GitLabCrop.prototype.onModalHide = function() {
      return this.modalCropImg.attr('src', '').cropper('destroy');
    };

    GitLabCrop.prototype.onUploadImageBtnClick = function(e) { // Remove attached image
      e.preventDefault(); // Destroy cropper instance
      this.setBlob();
      this.setPreview();
      this.modalCrop.modal('hide');
      return this.fileInput.val('');
    };

    GitLabCrop.prototype.onActionBtnClick = function(btn) {
      var data, result;
      data = $(btn).data();
      if (this.modalCropImg.data('cropper') && data.method) {
        return result = this.modalCropImg.cropper(data.method, data.option);
      }
    };

    GitLabCrop.prototype.onFileInputChange = function(e, input) {
      return this.readFile(input);
    };

    GitLabCrop.prototype.readFile = function(input) {
      var _this, reader;
      _this = this;
      reader = new FileReader;
      reader.onload = function() {
        _this.modalCropImg.attr('src', reader.result);
        return _this.modalCrop.modal('show');
      };
      return reader.readAsDataURL(input.files[0]);
    };

    GitLabCrop.prototype.dataURLtoBlob = function(dataURL) {
      var array, binary, i, k, len, v;
      binary = atob(dataURL.split(',')[1]);
      array = [];
      for (k = i = 0, len = binary.length; i < len; k = ++i) {
        v = binary[k];
        array.push(binary.charCodeAt(k));
      }
      return new Blob([new Uint8Array(array)], {
        type: 'image/png'
      });
    };

    GitLabCrop.prototype.setPreview = function() {
      var filename;
      this.previewImage.attr('src', this.dataURL);
      filename = this.fileInput.val().replace(FILENAMEREGEX, '');
      return this.filename.text(filename);
    };

    GitLabCrop.prototype.setBlob = function() {
      this.dataURL = this.modalCropImg.cropper('getCroppedCanvas', {
        width: 200,
        height: 200
      }).toDataURL('image/png');
      return this.croppedImageBlob = this.dataURLtoBlob(this.dataURL);
    };

    GitLabCrop.prototype.getBlob = function() {
      return this.croppedImageBlob;
    };

    return GitLabCrop;

  })();

  $.fn.glCrop = function(opts) {
    return this.each(function() {
      return $(this).data('glcrop', new GitLabCrop(this, opts));
    });
  };

}).call(this);
