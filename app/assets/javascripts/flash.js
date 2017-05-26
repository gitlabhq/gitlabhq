export default function showFlash(message, type = 'alert', parent = null) {
  const $flashContainer = parent ?
    parent.find('.flash-container') : $('.flash-container-page');

  const containerClasses = $flashContainer.parent().hasClass('content-wrapper') ?
    'container-fluid container-limited' : '';

  const $flash = $(`
    <div class="flash-${type}">
      <div class="flash-text ${containerClasses}">
        ${message}
      </div>
    </div>
  `).on('click', () => $flash.fadeOut());

  $flashContainer.empty().append($flash).show();
}

// global name capitalized for legacy reasons
window.Flash = showFlash;
