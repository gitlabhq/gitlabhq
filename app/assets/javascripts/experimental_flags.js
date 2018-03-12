import $ from 'jquery';
import Cookies from 'js-cookie';

export default () => {
  $('.js-experiment-feature-toggle').on('change', (e) => {
    const el = e.target;

    Cookies.set(el.name, el.value, {
      expires: 365 * 10,
    });

    document.body.scrollTop = 0;
    window.location.reload();
  });
};
