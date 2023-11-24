import $ from 'jquery';

export default function initClonePanel() {
  const $cloneOptions = $('ul.clone-options-dropdown');
  if ($cloneOptions.length) {
    const $cloneUrlField = $('#clone_url');
    const $cloneBtnLabel = $('.js-git-clone-holder .js-clone-dropdown-label');
    const mobileCloneField = document.querySelector(
      '.js-mobile-git-clone .js-clone-dropdown-label',
    );

    const selectedCloneOption = $cloneBtnLabel.text().trim();
    if (selectedCloneOption.length > 0) {
      $(`a:contains('${selectedCloneOption}')`, $cloneOptions).addClass('is-active');
    }

    $('.js-clone-links a', $cloneOptions).on('click', (e) => {
      const $this = $(e.currentTarget);
      const url = $this.attr('href');
      if (
        url &&
        (url.startsWith('vscode://') ||
          url.startsWith('xcode://') ||
          url.startsWith('jetbrains://'))
      ) {
        // Clone with "..." should open like a normal link
        return;
      }
      e.preventDefault();
      const cloneType = $this.data('cloneType');

      $('.is-active', $cloneOptions).removeClass('is-active');
      $(`a[data-clone-type="${cloneType}"]`).each(function switchProtocol() {
        const $el = $(this);
        const activeText = $el.find('.dropdown-menu-inner-title').text();
        const $container = $el.closest('.js-git-clone-holder, .js-mobile-git-clone');
        const $label = $container.find('.js-clone-dropdown-label');

        $el.toggleClass('is-active');
        $label.text(activeText);
      });

      if (mobileCloneField) {
        mobileCloneField.dataset.clipboardText = url;
      } else {
        $cloneUrlField.val(url);
      }
      $('.js-git-empty .js-clone').text(url);
    });
  }
}
