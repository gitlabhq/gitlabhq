export default class VersionCheckImage {
  static bindErrorEvent(imageElement) {
    imageElement.off('error').on('error', () => imageElement.hide());
  }
}
