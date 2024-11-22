/* globals LIVE_RELOAD */
const div = document.createElement('div');

Object.assign(div.style, {
  width: '100vw',
  height: '100vh',
  position: 'fixed',
  top: 0,
  left: 0,
  'z-index': 100000,
  background: 'rgba(0,0,0,0.9)',
  'font-size': '20px',
  'font-family': 'monospace',
  color: 'white',
  padding: '2.5em',
  'text-align': 'center',
});

const reloadMessage = LIVE_RELOAD
  ? 'You have live_reload enabled, the page will reload automatically when complete.'
  : 'You have live_reload disabled, the page will reload automatically in a few seconds.';

// eslint-disable-next-line no-unsanitized/property
div.innerHTML = `
<!-- https://github.com/webpack/media/blob/master/logo/icon-square-big.svg -->
<svg height="50" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 1200">
  <path fill="#FFF" d="M600 0l530.3 300v600L600 1200 69.7 900V300z"/>
  <path fill="#8ED6FB" class="st1" d="M1035.6 879.3l-418.1 236.5V931.6L878 788.3l157.6 91zm28.6-25.9V358.8l-153 88.3V765l153 88.4zm-901.5 25.9l418.1 236.5V931.6L320.3 788.3l-157.6 91zm-28.6-25.9V358.8l153 88.3V765l-153 88.4zM152 326.8L580.8 84.2v178.1L306.1 413.4l-2.1 1.2-152-87.8zm894.3 0L617.5 84.2v178.1l274.7 151.1 2.1 1.2 152-87.8z"/>
  <path fill="#1C78C0" d="M580.8 889.7l-257-141.3v-280l257 148.4v272.9zm36.7 0l257-141.3v-280l-257 148.4v272.9zm-18.3-283.6zM341.2 436l258-141.9 258 141.9-258 149-258-149z"/>
</svg>

<h1 style="color:white">✨ webpack is compiling frontend assets ✨</h1>
<p>
  To reduce GDK memory consumption, incremental on-demand compiling is on by default.<br />
  You can disable this within gdk.yml.
  Learn more <a href="https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md#webpack-settings">here</a>.
</p>
<p>
  ${reloadMessage}<br />
  If it doesn't, please <a href="">reload the page manually</a>.
</p>
<div class="gl-card gl-max-w-limited gl-m-auto">
  <div class="gl-card-body">
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 410 404" width="100">
      <path fill="url(#a)" d="m399.641 59.525-183.998 329.02c-3.799 6.793-13.559 6.833-17.415.073L10.582 59.556C6.38 52.19 12.68 43.266 21.028 44.76l184.195 32.923c1.175.21 2.378.208 3.553-.006l180.343-32.87c8.32-1.517 14.649 7.337 10.522 14.719Z"/>
      <path fill="url(#b)" d="M292.965 1.574 156.801 28.255a5 5 0 0 0-4.03 4.611l-8.376 141.464c-.197 3.332 2.863 5.918 6.115 5.168l37.91-8.749c3.547-.818 6.752 2.306 6.023 5.873l-11.263 55.153c-.758 3.712 2.727 6.886 6.352 5.785l23.415-7.114c3.63-1.102 7.118 2.081 6.35 5.796l-17.899 86.633c-1.12 5.419 6.088 8.374 9.094 3.728l2.008-3.103 110.954-221.428c1.858-3.707-1.346-7.935-5.418-7.15l-39.022 7.532c-3.667.707-6.787-2.708-5.752-6.296l25.469-88.291c1.036-3.594-2.095-7.012-5.766-6.293Z"/>
      <defs>
        <linearGradient id="a" x1="6" x2="235" y1="33" y2="344" gradientUnits="userSpaceOnUse"><stop stop-color="#41D1FF"/><stop offset="1" stop-color="#BD34FE"/></linearGradient>
        <linearGradient id="b" x1="194.651" x2="236.076" y1="8.818" y2="292.989" gradientUnits="userSpaceOnUse"><stop stop-color="#FFEA83"/><stop offset=".083" stop-color="#FFDD35"/><stop offset="1" stop-color="#FFA800"/></linearGradient>
      </defs>
    </svg>
    <h2>Don't want to see this message anymore?</h2>
    <p class="gl-text-default">
      Follow the documentation to switch to using Vite.<br />
      Vite compiles frontend assets faster and eliminates the need for this message.
    </p>
    <a href="https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md?ref_type=heads#vite-settings" rel="noopener noreferrer" target="_blank" class="btn btn-confirm btn-md gl-button">
      <span class="gl-button-text">Switch to Vite</span>
    </a>
  </div>
</div>
`;

document.body.append(div);

if (!LIVE_RELOAD) {
  setTimeout(() => {
    window.location.reload();
  }, 5000);
}
