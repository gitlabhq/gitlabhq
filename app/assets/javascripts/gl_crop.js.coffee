class GitLabCrop
  constructor: (el, opts = {}) ->
    # Input file
    @fileInput = $(el)

    # Set defaults
    {
      @filename
      @previewImage = $('.avatar-image .avatar')
      @form = @fileInput.parents('form')
      @modalCrop = '.modal-profile-crop'
      @exportWidth = 200
      @exportHeight = 200
      @cropBoxWidth = 200
      @cropBoxHeight = 200

      # Button where user clicks to open file dialog
      # If not passed as argument let's pick a default one
      @pickImageEl = @fileInput.parent().find('.js-choose-user-avatar-button')
      @uploadImageBtn = $('.js-upload-user-avatar')
    } = opts

    # Ensure @modalCrop is a jQuery Object
    @modalCrop = $(@modalCrop)
    @modalCropImg = $('.modal-profile-crop-image')
    @cropActionsBtn = @modalCrop.find('[data-method]')

    @bindEvents()

  bindEvents: ->
    self = @
    @fileInput.on 'change', (e) ->
      self.onFileInputChange(e, @)

    @pickImageEl.on 'click', @onPickImageClick
    @modalCrop.on 'shown.bs.modal', @onModalShow
    @modalCrop.on 'hidden.bs.modal', @onModalHide
    @uploadImageBtn.on 'click', @onUploadImageBtnClick
    @cropActionsBtn.on 'click', (e) ->
      btn = @
      self.onActionBtnClick(btn)
    @croppedImageBlob = null

  onPickImageClick: =>
    @fileInput.trigger('click')

  onModalShow: =>
    self = @
    @modalCropImg.cropper(
      viewMode: 1
      center: false
      aspectRatio: 1
      modal: true
      scalable: false
      rotatable: false
      zoomable: true
      dragMode: 'move'
      guides: false
      zoomOnTouch: false
      zoomOnWheel: false
      cropBoxMovable: false
      cropBoxResizable: false
      toggleDragModeOnDblclick: false
      built: ->
        container = $(@).cropper 'getContainerData'
        cropBoxWidth = self.cropBoxWidth;
        cropBoxHeight = self.cropBoxHeight;

        $(@).cropper('setCropBoxData',
          width: cropBoxWidth,
          height: cropBoxHeight,
          left: (container.width - cropBoxWidth) / 2,
          top: (container.height - cropBoxHeight) / 2
        )
    )


  onModalHide: =>
    @modalCropImg
      .attr('src', '') # Remove attached image
      .cropper('destroy') # Destroy cropper instance

  onUploadImageBtnClick: (e) =>
    e.preventDefault()
    @setBlob()
    @setPreview()
    @modalCrop.modal('hide')

  onActionBtnClick: (btn) ->
    data = $(btn).data()

    if @modalCropImg.data('cropper') && data.method
      data = $.extend {}, data
      result = @modalCropImg.cropper data.method, data.option

  onFileInputChange: (e, input) ->
    @readFile(input)

  readFile: (input) ->
    self = @
    reader = new FileReader
    reader.onload = ->
      self.modalCropImg.attr('src', reader.result)
      self.modalCrop.modal('show')

    reader.readAsDataURL(input.files[0])

  dataURLtoBlob: (dataURL) ->
    binary = atob(dataURL.split(',')[1])
    array = []
    for v, k in  binary
      array.push(binary.charCodeAt(k))
    new Blob([new Uint8Array(array)], type: 'image/png')

  setPreview: ->
    @previewImage.attr('src', @dataURL)

  setBlob: ->
    @dataURL = @modalCropImg.cropper('getCroppedCanvas',
        width: 200
        height: 200
      ).toDataURL('image/png')
    @croppedImageBlob = @dataURLtoBlob(@dataURL)

  getBlob: ->
    @croppedImageBlob

$.fn.glCrop = (opts) ->
  return @.each ->
    $(@).data('glcrop', new GitLabCrop(@, opts))
