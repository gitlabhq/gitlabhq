(function (w) {
  if (!window.gl) {
    window.gl = {};
  }

  gl.boardSortableDefaultOptions = {
    forceFallback: true,
    fallbackClass: 'is-dragging',
    fallbackOnBody: true,
    ghostClass: 'is-ghost',
    filter: '.has-tooltip',
    scrollSensitivity: 50,
    scrollSpeed: 10,
    onStart: function () {
      document.body.classList.add('is-dragging');
    },
    onEnd: function () {
      document.body.classList.remove('is-dragging');
    }
  };
})(window);
