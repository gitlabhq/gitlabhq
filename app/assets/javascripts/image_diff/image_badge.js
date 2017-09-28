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
      this.browser = this.generateBrowserMeta(options.imageEl);
    }
  }

  generateBrowserMeta(imageEl) {
    const { x, y, width, height } = this.actual;

    const browserImageWidth = imageEl.width;
    const browserImageHeight = imageEl.height;

    const widthRatio = browserImageWidth / width;
    const heightRatio = browserImageHeight / height;

    return {
      x: Math.round(x * widthRatio),
      y: Math.round(y * heightRatio),
      width: browserImageWidth,
      height: browserImageHeight,
    };
  }
}
