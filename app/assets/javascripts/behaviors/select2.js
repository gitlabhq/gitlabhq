import $ from 'jquery';

export default () => {
  if ($('select.select2').length) {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        $('select.select2').select2({
          width: 'resolve',
          minimumResultsForSearch: 10,
          dropdownAutoWidth: true,
        });

        // Close select2 on escape
        $('.js-select2').on('select2-close', () => {
          setTimeout(() => {
            $('.select2-container-active').removeClass('select2-container-active');
            $(':focus').blur();
          }, 1);
        });
      })
      .catch(() => {});
  }
};
