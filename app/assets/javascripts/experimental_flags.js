import Cookies from 'js-cookie';

export default () => {
  $('.js-experiment-feature-toggle').on('change', (e) => {
    const el = e.target;

    Cookies.set(el.name, el.value, {
      expires: 365 * 10,
    });
  });
};
