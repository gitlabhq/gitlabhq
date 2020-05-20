import Editor from '~/editor/editor_lite';
import initEditor from '~/snippet/snippet_bundle';
import { setHTMLFixture } from 'helpers/fixtures';

jest.mock('~/editor/editor_lite', () => jest.fn());

describe('Snippet editor', () => {
  let editorEl;
  let contentEl;
  let fileNameEl;
  let form;

  const mockName = 'foo.bar';
  const mockContent = 'Foo Bar';
  const updatedMockContent = 'New Foo Bar';

  const mockEditor = {
    createInstance: jest.fn(),
    updateModelLanguage: jest.fn(),
    getValue: jest.fn().mockReturnValueOnce(updatedMockContent),
  };
  Editor.mockImplementation(() => mockEditor);

  function setUpFixture(name, content) {
    setHTMLFixture(`
      <div class="snippet-form-holder">
        <form>
          <input class="js-snippet-file-name" type="text" value="${name}">
          <input class="snippet-file-content" type="hidden" value="${content}">
          <pre id="editor"></pre>
        </form>
      </div>
    `);
  }

  function bootstrap(name = '', content = '') {
    setUpFixture(name, content);
    editorEl = document.getElementById('editor');
    contentEl = document.querySelector('.snippet-file-content');
    fileNameEl = document.querySelector('.js-snippet-file-name');
    form = document.querySelector('.snippet-form-holder form');

    initEditor();
  }

  function createEvent(name) {
    return new Event(name, {
      view: window,
      bubbles: true,
      cancelable: true,
    });
  }

  beforeEach(() => {
    bootstrap(mockName, mockContent);
  });

  it('correctly initializes Editor', () => {
    expect(mockEditor.createInstance).toHaveBeenCalledWith({
      el: editorEl,
      blobPath: mockName,
      blobContent: mockContent,
    });
  });

  it('listens to file name changes and updates syntax highlighting of code', () => {
    expect(mockEditor.updateModelLanguage).not.toHaveBeenCalled();

    const event = createEvent('change');

    fileNameEl.value = updatedMockContent;
    fileNameEl.dispatchEvent(event);

    expect(mockEditor.updateModelLanguage).toHaveBeenCalledWith(updatedMockContent);
  });

  it('listens to form submit event and populates the hidden field with most recent version of the content', () => {
    expect(contentEl.value).toBe(mockContent);

    const event = createEvent('submit');

    form.dispatchEvent(event);
    expect(contentEl.value).toBe(updatedMockContent);
  });
});
