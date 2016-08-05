(function (w) {
  if (!window.gl) {
    window.gl = {};
  }

  gl.boardSortableDefaultOptions = {
    animation: 150,
    forceFallback: true,
    fallbackClass: 'is-dragging',
    ghostClass: 'is-ghost',
    scrollSensitivity: 150,
    scrollSpeed: 50,
    onStart: function () {
      document.body.classList.add('is-dragging');
    },
    onEnd: function () {
      document.body.classList.remove('is-dragging');
    }
  };
})(window);
