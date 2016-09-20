(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Labels = (function() {
    function Labels() {
      this.setSuggestedColor = bind(this.setSuggestedColor, this);
      this.updateColorPreview = bind(this.updateColorPreview, this);
      var form;
      form = $('.label-form');
      this.cleanBinding();
      this.addBinding();
      this.updateColorPreview();
    }

    Labels.prototype.addBinding = function() {
      $(document).on('click', '.suggest-colors a', this.setSuggestedColor);
      return $(document).on('input', 'input#label_color', this.updateColorPreview);
    };

    Labels.prototype.cleanBinding = function() {
      $(document).off('click', '.suggest-colors a');
      return $(document).off('input', 'input#label_color');
    };

    Labels.prototype.updateColorPreview = function() {
      var previewColor;
      previewColor = $('input#label_color').val();
      return $('div.label-color-preview').css('background-color', previewColor);
    // Updates the the preview color with the hex-color input
    };

    // Updates the preview color with a click on a suggested color
    Labels.prototype.setSuggestedColor = function(e) {
      var color;
      color = $(e.currentTarget).data('color');
      $('input#label_color').val(color);
      this.updateColorPreview();
      // Notify the form, that color has changed
      $('.label-form').trigger('keyup');
      return e.preventDefault();
    };

    return Labels;

  })();

}).call(this);
