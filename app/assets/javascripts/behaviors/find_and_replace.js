import $ from 'jquery';

if (gon.features?.findAndReplace) {
  $(document).on('markdown-editor:find-and-replace', (e, keyboardEvent) => {
    const $target = $(keyboardEvent.target);

    if ($target.is('textarea.markdown-area')) {
      $(document).triggerHandler('markdown-editor:find-and-replace:show', [
        $target.closest('form'),
      ]);
      keyboardEvent.preventDefault();
    }
  });
}
