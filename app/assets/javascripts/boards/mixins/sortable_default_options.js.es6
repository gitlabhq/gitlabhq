((w) => {
  if (!window.gl) {
    window.gl = {};
  }

  gl.boardSortableDefaultOptions = {
    forceFallback: true,
    fallbackClass: 'is-dragging',
    fallbackOnBody: true,
    ghostClass: 'is-ghost',
    filter: '.has-tooltip',
    scrollSensitivity: 100,
    scrollSpeed: 20,
    onStart: function () {
      document.body.classList.add('is-dragging');
    },
    onEnd: function () {
      document.body.classList.remove('is-dragging');
    }
  };
})(window);
