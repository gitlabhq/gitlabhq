/* eslint-disable func-names, space-before-function-paren, consistent-return, no-var, no-undef, no-else-return, prefer-arrow-callback, max-len, no-console */
// Renders math using KaTeX in any element with the
// `js-render-math` class
//
// ### Example Markup
//
//   <code class="js-render-math"></div>
//
(function() {
  // Only load once
  var katexLoaded = false;

  // Loop over all math elements and render math
  var renderWithKaTeX = function (elements) {
    elements.each(function () {
      var mathNode = $('<span></span>');
      var $this = $(this);

      var display = $this.attr('data-math-style') === 'display';
      try {
        katex.render($this.text(), mathNode.get(0), { displayMode: display });
        mathNode.insertAfter($this);
        $this.remove();
      } catch (err) {
        // What can we do??
        console.log(err.message);
      }
    });
  };

  $.fn.renderMath = function() {
    var $this = this;
    if ($this.length === 0) return;

    if (katexLoaded) renderWithKaTeX($this);
    else {
      // Request CSS file so it is in the cache
      $.get(gon.katex_css_url, function() {
        var css = $('<link>',
          { rel: 'stylesheet',
            type: 'text/css',
            href: gon.katex_css_url,
          });
        css.appendTo('head');

        // Load KaTeX js
        $.getScript(gon.katex_js_url, function() {
          katexLoaded = true;
          renderWithKaTeX($this); // Run KaTeX
        });
      });
    }
  };
}).call(window);
