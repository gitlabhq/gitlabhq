export default function initLogoAnimation() {
  window.addEventListener('beforeunload', () => {
    document.querySelector('.tanuki-logo')?.classList.add('animate');
  });
}
