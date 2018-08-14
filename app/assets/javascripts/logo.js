import $ from 'jquery';

export default function initLogoAnimation() {
  window.addEventListener('beforeunload', () => {
    $('.tanuki-logo').addClass('animate');
  });
}
