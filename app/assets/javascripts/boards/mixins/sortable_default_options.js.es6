((w) => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.getBoardSortableDefaultOptions = (obj) => {
    let defaultSortOptions = {
      forceFallback: true,
      fallbackClass: 'is-dragging',
      fallbackOnBody: true,
      ghostClass: 'is-ghost',
      filter: '.has-tooltip',
      scrollSensitivity: 100,
      scrollSpeed: 20,
      onStart () {
        document.body.classList.add('is-dragging');
      },
      onEnd () {
        document.body.classList.remove('is-dragging');
      }
    }

    Object.keys(obj).forEach((key) => { defaultSortOptions[key] = obj[key]; });
    return defaultSortOptions;
  };
})(window);
