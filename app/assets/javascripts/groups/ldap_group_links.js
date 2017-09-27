document.addEventListener('DOMContentLoaded', () => {
  const $cnLink = $('.cn-link');
  const $filterLink = $('.filter-link');

  const showGroupLink = () => {
    const $checkedSync = $('input[name="sync_method"]:checked').val() === 'group';

    $cnLink.toggle($checkedSync);
    $filterLink.toggle(!$checkedSync);
  };

  $('input[name="sync_method"]').on('change', showGroupLink);
  showGroupLink();
});
