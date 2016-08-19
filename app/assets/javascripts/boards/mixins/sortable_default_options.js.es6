((w) => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.onStart = () => {
    $('.has-tooltip').tooltip('hide')
      .tooltip('disable');
    document.body.classList.add('is-dragging');
  };

  gl.issueBoards.onEnd = () => {
    $('.has-tooltip').tooltip('enable');
    document.body.classList.remove('is-dragging');
  };

  gl.issueBoards.getBoardSortableDefaultOptions = (obj) => {
    let defaultSortOptions = {
      forceFallback: true,
      fallbackClass: 'is-dragging',
      fallbackOnBody: true,
      ghostClass: 'is-ghost',
      filter: '.has-tooltip',
      scrollSensitivity: 100,
      scrollSpeed: 20,
      onStart: gl.issueBoards.onStart,
      onEnd: gl.issueBoards.onEnd
    }

    Object.keys(obj).forEach((key) => { defaultSortOptions[key] = obj[key]; });
    return defaultSortOptions;
  };
})(window);
