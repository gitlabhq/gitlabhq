import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initFilePickers from '~/file_pickers';

describe('initFilePickers', () => {
  let filePicker;
  let button;
  let input;
  let error;
  let filenameDisplay;

  const dummyContent = new Array(250 * 1024).fill('A').join(''); // 250 KB of data
  const largeFile = new File([dummyContent], 'test/path/large_image.jpg', {
    type: 'image/jpeg',
  });
  const file = new File(['dummy content'], 'test/path/image.jpg', {
    type: 'image/jpeg',
  });

  beforeEach(() => {
    setHTMLFixture(`
      <form>
        <div class="js-filepicker" data-max-file-size="200">
          <button type="button" class="js-filepicker-button">
            <span class="gl-button-text">Choose file…</span>
          </button>
          <span class="file_name js-filepicker-filename">Choose file...</span>
          <input accept type="file" class="js-filepicker-input hidden" />
          <span class="js-filepicker-error gl-hidden gl-text-danger">The maximum file size is 200 KiB.</span
        </div>
      </form>
    `);

    filePicker = document.querySelector('.js-filepicker');
    button = filePicker.querySelector('.js-filepicker-button');
    input = filePicker.querySelector('.js-filepicker-input');
    error = filePicker.querySelector('.js-filepicker-error');
    filenameDisplay = filePicker.querySelector('.js-filepicker-filename');

    initFilePickers();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should trigger the file input click when button is clicked', () => {
    const inputClickSpy = jest.spyOn(input, 'click');
    button.click();

    expect(inputClickSpy).toHaveBeenCalled();
  });

  it('should display the selected file name after selecting a file', () => {
    Object.defineProperty(input, 'files', { value: [file] });
    input.dispatchEvent(new Event('change'));

    expect(filenameDisplay.textContent).toBe('image.jpg');
  });

  it('should show an error if the file size exceeds the max limit', () => {
    Object.defineProperty(input, 'files', { value: [largeFile] });
    input.dispatchEvent(new Event('change'));

    expect(button.classList).toContain('btn-danger', 'btn-danger-secondary');
    expect(error.classList).toContain('!gl-block');
    expect(input.value).toBe('');
  });

  it('should clear error styles and reset filename after a valid file is selected', () => {
    // Simulate previous error
    button.classList.add('btn-danger', 'btn-danger-secondary');
    error.classList.add('!gl-block');

    Object.defineProperty(input, 'files', { value: [file] });
    input.dispatchEvent(new Event('change'));

    expect(button.classList).not.toContain('btn-danger', 'btn-danger-secondary');
    expect(error.classList).not.toContain('!gl-block');
    expect(filenameDisplay.textContent).toBe('image.jpg');
  });
});
