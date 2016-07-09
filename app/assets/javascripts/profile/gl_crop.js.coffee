class GitLabCrop
  # Matches everything but the file name
  FILENAMEREGEX = /^.*[\\\/]/

  constructor: (input, opts = {}) ->
    @fileInput = $(input)

    # We should rename to avoid spec to fail
    # Form will submit the proper input filed with a file using FormData
    @fileInput
      .attr('name', "#{@fileInput.attr('name')}-trigger")
      .attr('id', "#{@fileInput.attr('id')}-trigger")

    # Set defaults
    {
      @exportWidth = 200
      @exportHeight = 200
      @cropBoxWidth = 200
      @cropBoxHeight = 200
      @form = @fileInput.parents('form')

      # Required params
      @filename
      @previewImage
      @modalCrop
      @pickImageEl
      @uploadImageBtn
      @modalCropImg
    } = opts

    # Ensure needed elements are jquery objects
    # If selector is provided we will convert them to a jQuery Object
    @filename = @getElement(@filename)
    @previewImage = @getElement(@previewImage)
    @pickImageEl = @getElement(@pickImageEl)

    # Modal elements usually are outside the @form element
    @modalCrop = if _.isString(@modalCrop) then $(@modalCrop) else @modalCrop
    @uploadImageBtn = if _.isString(@uploadImageBtn) then $(@uploadImageBtn) else @uploadImageBtn
    @modalCropImg = if _.isString(@modalCropImg) then $(@modalCropImg) else @modalCropImg

    @cropActionsBtn = @modalCrop.find('[data-method]')

    @bindEvents()

  getElement: (selector) ->
    $(selector, @form)

  bindEvents: ->
    _this = @
    @fileInput.on 'change', (e) ->
      _this.onFileInputChange(e, @)

    @pickImageEl.on 'click', @onPickImageClick
    @modalCrop.on 'shown.bs.modal', @onModalShow
    @modalCrop.on 'hidden.bs.modal', @onModalHide
    @uploadImageBtn.on 'click', @onUploadImageBtnClick
    @cropActionsBtn.on 'click', (e) ->
      btn = @
      _this.onActionBtnClick(btn)
    @croppedImageBlob = null

  onPickImageClick: =>
    @fileInput.trigger('click')

  onModalShow: =>
    _this = @
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
        $image = $(@)
        container = $image.cropper 'getContainerData'
        cropBoxWidth = _this.cropBoxWidth;
        cropBoxHeight = _this.cropBoxHeight;

        $image.cropper('setCropBoxData',
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
    @fileInput.val('')

  onActionBtnClick: (btn) ->
    data = $(btn).data()

    if @modalCropImg.data('cropper') && data.method
      result = @modalCropImg.cropper data.method, data.option

  onFileInputChange: (e, input) ->
    @readFile(input)

  readFile: (input) ->
    _this = @
    reader = new FileReader
    reader.onload = ->
      _this.modalCropImg.attr('src', reader.result)
      _this.modalCrop.modal('show')

    reader.readAsDataURL(input.files[0])

  dataURLtoBlob: (dataURL) ->
    binary = atob(dataURL.split(',')[1])
    array = []
    for v, k in  binary
      array.push(binary.charCodeAt(k))
    new Blob([new Uint8Array(array)], type: 'image/png')

  setPreview: ->
    @previewImage.attr('src', @dataURL)
    filename = @fileInput.val().replace(FILENAMEREGEX, '')
    @filename.text(filename)

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
