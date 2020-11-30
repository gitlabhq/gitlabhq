import $ from 'jquery';
import { loadCSSFile } from '../lib/utils/css_utils';

export default () => {
  const $select2Elements = $('select.select2');
  if ($select2Elements.length) {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        // eslint-disable-next-line promise/no-nesting
        loadCSSFile(gon.select2_css_path)
          .then(() => {
            $select2Elements.select2({
              width: 'resolve',
              minimumResultsForSearch: 10,
              dropdownAutoWidth: true,
            });

            // Close select2 on escape
            $('.js-select2').on('select2-close', () => {
              requestAnimationFrame(() => {
                $('.select2-container-active').removeClass('select2-container-active');
                $(':focus').blur();
              });
            });
          })
          .catch(() => {});
      })
      .catch(() => {});
  }
};
