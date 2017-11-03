export default function initLogoAnimation() {
  window.addEventListener('beforeunload', () => {
    $('.tanuki-logo').addClass('animate');
  });
}
