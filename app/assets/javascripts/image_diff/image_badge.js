import imageDiffHelper from './helpers/index';

const defaultMeta = {
  x: 0,
  y: 0,
  width: 0,
  height: 0,
};

export default class ImageBadge {
  constructor(options) {
    const { noteId, discussionId } = options;

    this.actual = options.actual || defaultMeta;
    this.browser = options.browser || defaultMeta;
    this.noteId = noteId;
    this.discussionId = discussionId;

    if (options.imageEl && !options.browser) {
      this.browser = imageDiffHelper.resizeCoordinatesToImageElement(options.imageEl, this.actual);
    }
  }
}
