export default class VersionCheckImage {
  static bindErrorEvent(imageElement) {
    // eslint-disable-next-line @gitlab/no-global-event-off
    imageElement.off('error').on('error', () => imageElement.hide());
  }
}
