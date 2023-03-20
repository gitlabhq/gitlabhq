import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import fileUpload, {
  getFilename,
  validateImageName,
  validateFileFromAllowList,
} from '~/lib/utils/file_upload';

describe('File upload', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <form>
        <button class="js-button" type="button">Click me!</button>
        <input type="text" class="js-input" />
        <span class="js-filename"></span>
      </form>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when there is a matching button and input', () => {
    beforeEach(() => {
      fileUpload('.js-button', '.js-input');
    });

    it('clicks file input after clicking button', () => {
      const btn = document.querySelector('.js-button');
      const input = document.querySelector('.js-input');

      jest.spyOn(input, 'click').mockReturnValue();

      btn.click();

      expect(input.click).toHaveBeenCalled();
    });

    it('updates file name text', () => {
      const input = document.querySelector('.js-input');

      input.value = 'path/to/file/index.js';

      input.dispatchEvent(new CustomEvent('change'));

      expect(document.querySelector('.js-filename').textContent).toEqual('index.js');
    });
  });

  it('fails gracefully when there is no matching button', () => {
    const input = document.querySelector('.js-input');
    const btn = document.querySelector('.js-button');
    fileUpload('.js-not-button', '.js-input');

    jest.spyOn(input, 'click').mockReturnValue();

    btn.click();

    expect(input.click).not.toHaveBeenCalled();
  });

  it('fails gracefully when there is no matching input', () => {
    const input = document.querySelector('.js-input');
    const btn = document.querySelector('.js-button');
    fileUpload('.js-button', '.js-not-input');

    jest.spyOn(input, 'click').mockReturnValue();

    btn.click();

    expect(input.click).not.toHaveBeenCalled();
  });
});

describe('getFilename', () => {
  it('returns file name', () => {
    const file = new File([], 'test.jpg');

    expect(getFilename(file)).toBe('test.jpg');
  });
});

describe('file name validator', () => {
  it('validate file name', () => {
    const file = new File([], 'test.jpg');

    expect(validateImageName(file)).toBe('test.jpg');
  });

  it('illegal file name should be rename to image.png', () => {
    const file = new File([], 'test<.png');

    expect(validateImageName(file)).toBe('image.png');
  });
});

describe('validateFileFromAllowList', () => {
  it('returns true if the file type is in the allowed list', () => {
    const allowList = ['.foo', '.bar'];
    const fileName = 'file.foo';

    expect(validateFileFromAllowList(fileName, allowList)).toBe(true);
  });

  it('returns false if the file type is in the allowed list', () => {
    const allowList = ['.foo', '.bar'];
    const fileName = 'file.baz';

    expect(validateFileFromAllowList(fileName, allowList)).toBe(false);
  });
});
