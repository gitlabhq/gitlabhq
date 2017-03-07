class VersionCheckImage {
  static bindErrorEvent(imageElement) {
    imageElement.off('error').on('error', () => imageElement.hide());
  }
}

window.gl = window.gl || {};
gl.VersionCheckImage = VersionCheckImage;

module.exports = VersionCheckImage;
