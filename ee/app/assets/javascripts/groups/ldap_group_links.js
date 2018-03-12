import $ from 'jquery';

export default () => {
  const showGroupLink = () => {
    const $cnLink = $('.cn-link');
    const $filterLink = $('.filter-link');
    if (!$cnLink.length || !$filterLink.length) return;

    const $checkedSync = $('input[name="sync_method"]:checked').val() === 'group';

    $cnLink.toggle($checkedSync);
    $filterLink.toggle(!$checkedSync);
  };

  $('input[name="sync_method"]').on('change', showGroupLink);
  showGroupLink();
};
