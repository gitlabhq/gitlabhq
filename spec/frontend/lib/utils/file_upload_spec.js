import fileUpload from '~/lib/utils/file_upload';

describe('File upload', () => {
  beforeEach(() => {
    setFixtures(`
      <form>
        <button class="js-button" type="button">Click me!</button>
        <input type="text" class="js-input" />
        <span class="js-filename"></span>
      </form>
    `);
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
