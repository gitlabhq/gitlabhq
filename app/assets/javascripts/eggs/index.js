/* eslint-disable no-param-reassign, no-plusplus, no-unused-vars */
// GitLab Easter Eggs
((gl) => {
  const ASSETS_PREFIX = '/assets';
  let isInitialized = false;
  gl.eggs = {};

  gl.eggs.partyParrotAvatars = () => {
    const avatars = document.querySelectorAll('img.avatar');
    avatars.forEach((avatar, i) => {
      avatar.setAttribute('src', `${ASSETS_PREFIX}/parrot.gif`);
    });
  };

  gl.eggs.initialize = () => {
    document.addEventListener('mousemove', (e) => {
      const eggsList = Object.keys(gl.eggs);
      if (!isInitialized) {
        eggsList.forEach((eggItem, i) => {
          if (eggItem !== 'initialize') {
            gl.eggs[eggItem]();
          }
        });
        isInitialized = true;
      }
    });
  };
})(window.gl || (window.gl = {}));
