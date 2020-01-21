import initImageDiffHelper from '~/image_diff/helpers/init_image_diff';
import ImageDiff from '~/image_diff/image_diff';
import ReplacedImageDiff from '~/image_diff/replaced_image_diff';

describe('initImageDiff', () => {
  let glCache;
  let fileEl;

  beforeEach(() => {
    window.gl = window.gl || (window.gl = {});
    glCache = window.gl;
    fileEl = document.createElement('div');
    fileEl.innerHTML = `
        <div class="diff-file"></div>
      `;

    jest.spyOn(ReplacedImageDiff.prototype, 'init').mockImplementation(() => {});
    jest.spyOn(ImageDiff.prototype, 'init').mockImplementation(() => {});
  });

  afterEach(() => {
    window.gl = glCache;
  });

  it('should initialize ImageDiff if js-single-image', () => {
    const diffFileEl = fileEl.querySelector('.diff-file');
    diffFileEl.innerHTML = `
        <div class="js-single-image">
        </div>
      `;

    const imageDiff = initImageDiffHelper.initImageDiff(fileEl, true, false);

    expect(ImageDiff.prototype.init).toHaveBeenCalled();
    expect(imageDiff.canCreateNote).toEqual(true);
    expect(imageDiff.renderCommentBadge).toEqual(false);
  });

  it('should initialize ReplacedImageDiff if js-replaced-image', () => {
    const diffFileEl = fileEl.querySelector('.diff-file');
    diffFileEl.innerHTML = `
        <div class="js-replaced-image">
        </div>
      `;

    const replacedImageDiff = initImageDiffHelper.initImageDiff(fileEl, false, true);

    expect(ReplacedImageDiff.prototype.init).toHaveBeenCalled();
    expect(replacedImageDiff.canCreateNote).toEqual(false);
    expect(replacedImageDiff.renderCommentBadge).toEqual(true);
  });
});
