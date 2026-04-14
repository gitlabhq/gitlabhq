import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';
import {
  CLICK,
  EXPAND_FILE,
  HIGHLIGHT_LINES,
  INVISIBLE,
  MOUNTED,
  VISIBLE,
} from '~/rapid_diffs/adapter_events';
import { settledScrollIntoView } from '~/rapid_diffs/utils/settled_scroll_into_view';
import { scrollPastCoveringElements } from '~/lib/utils/sticky';

jest.mock('~/rapid_diffs/utils/settled_scroll_into_view');
jest.mock('~/lib/utils/sticky');

describe('DiffFile Web Component', () => {
  const fileData = JSON.stringify({ viewer: 'current', custom: 'bar' });
  const html = `
    <div data-rapid-diffs>
      <diff-file data-file-data='${fileData}' id="fileHash">
        <article>
          <button data-click="foo"></button>
        </article>
      </diff-file>
    </div>
  `;
  let app;
  let adapter;
  let adapterMountedCleanup;

  const getDiffElement = () => document.querySelector('article');
  const getWebComponentElement = () => document.querySelector('diff-file');

  const triggerVisibility = (isIntersecting) => {
    const target = getWebComponentElement();
    // eslint-disable-next-line no-unused-expressions
    isIntersecting ? target.onVisible({}) : target.onInvisible({});
  };

  const createDefaultAdapter = () => ({
    [CLICK]: jest.fn(),
    clicks: {
      foo: jest.fn(),
    },
    [VISIBLE]: jest.fn(),
    [INVISIBLE]: jest.fn(),
    [MOUNTED]: jest.fn((onUnmounted) => {
      adapterMountedCleanup = jest.fn();
      onUnmounted(adapterMountedCleanup);
    }),
  });

  const initRapidDiffsApp = (currentAdapter = createDefaultAdapter(), appData = {}) => {
    adapter = currentAdapter;
    app = {
      adapterConfig: { current: [currentAdapter] },
      appData,
      observe: jest.fn(),
      unobserve: jest.fn(),
    };
  };

  const delegatedClick = (element) => {
    let event;
    element.addEventListener(
      'click',
      (e) => {
        event = e;
      },
      { once: true },
    );
    element.click();
    getWebComponentElement().onClick(event);
  };

  const mount = (customAdapter) => {
    initRapidDiffsApp(customAdapter);
    document.body.innerHTML = html;
    getWebComponentElement().mount(app);
  };

  const getContext = () => ({
    appData: app.appData,
    diffElement: getDiffElement(),
    data: {
      custom: 'bar',
      viewer: 'current',
    },
    sink: {},
    id: 'fileHash',
    selectFile: expect.any(Function),
    trigger: expect.any(Function),
    replaceWith: expect.any(Function),
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    adapterMountedCleanup = undefined;
  });

  it('observes diff element', () => {
    mount();
    expect(app.observe).toHaveBeenCalledWith(getWebComponentElement());
  });

  it('triggers mounted event', () => {
    let emitted = false;
    document.addEventListener(DIFF_FILE_MOUNTED, () => {
      emitted = true;
    });
    mount();
    expect(adapter[MOUNTED]).toHaveBeenCalled();
    expect(adapter[MOUNTED].mock.instances[0]).toStrictEqual(getContext());
    expect(emitted).toBe(true);
  });

  it('properly unmounts', () => {
    mount();
    const element = getWebComponentElement();
    document.body.innerHTML = '';
    expect(app.unobserve).toHaveBeenCalledWith(element);
    expect(adapterMountedCleanup).toHaveBeenCalled();
  });

  it('can self replace', () => {
    const focusFirstButton = jest.fn();
    const mockNode = { focusFirstButton };
    mount({
      [MOUNTED]() {
        this.replaceWith(mockNode);
      },
    });
    expect(focusFirstButton).toHaveBeenCalled();
  });

  it('#selectFile', () => {
    mount();
    const element = getWebComponentElement();
    const root = document.querySelector('[data-rapid-diffs]');
    element.selectFile();
    expect(settledScrollIntoView).toHaveBeenCalledWith(element, root);
  });

  describe('#selectLine', () => {
    const lineHtml = `
      <div data-rapid-diffs>
        <diff-file data-file-data='${fileData}' id="fileHash">
          <article>
            <table><tbody>
              <tr>
                <td data-position="old"><span data-line-number="5"></span></td>
                <td data-position="new"><span data-line-number="10"></span></td>
              </tr>
            </tbody></table>
          </article>
        </diff-file>
      </div>
    `;

    const mountWithLines = (customAdapter) => {
      initRapidDiffsApp(customAdapter);
      document.body.innerHTML = lineHtml;
      document.elementFromPoint = jest.fn(() => null);
      getWebComponentElement().mount(app);
    };

    it('triggers EXPAND_FILE and HIGHLIGHT_LINES', async () => {
      const expandFile = jest.fn();
      const highlightLines = jest.fn();
      mountWithLines({
        [EXPAND_FILE]: expandFile,
        [HIGHLIGHT_LINES]: highlightLines,
        [MOUNTED]: jest.fn(),
      });
      await getWebComponentElement().selectLine(5, 10);
      expect(expandFile).toHaveBeenCalled();
      expect(highlightLines).toHaveBeenCalledWith({
        start: { old_line: 5, new_line: 10 },
        end: { old_line: 5, new_line: 10 },
      });
    });

    it('scrolls to the line row and adjusts for covering elements', async () => {
      settledScrollIntoView.mockResolvedValue();
      mountWithLines({
        [MOUNTED]: jest.fn(),
        [EXPAND_FILE]: jest.fn(),
        [HIGHLIGHT_LINES]: jest.fn(),
      });
      const row = getDiffElement().querySelector('tr');
      await getWebComponentElement().selectLine(5, 10);
      expect(settledScrollIntoView).toHaveBeenCalledWith(row, expect.any(HTMLElement));
      expect(scrollPastCoveringElements).toHaveBeenCalledWith(row);
    });

    it('falls back to selectFile when line is not found', async () => {
      mountWithLines({
        [MOUNTED]: jest.fn(),
        [EXPAND_FILE]: jest.fn(),
        [HIGHLIGHT_LINES]: jest.fn(),
      });
      settledScrollIntoView.mockClear();
      await getWebComponentElement().selectLine(999, 999);
      const element = getWebComponentElement();
      const root = document.querySelector('[data-rapid-diffs]');
      expect(settledScrollIntoView).toHaveBeenCalledWith(element, root);
    });
  });

  describe('when visible', () => {
    beforeEach(() => {
      mount();
    });

    it('handles all clicks', () => {
      triggerVisibility(true);
      delegatedClick(getDiffElement());
      expect(adapter[CLICK]).toHaveBeenCalledWith(expect.any(MouseEvent));
      expect(adapter[CLICK].mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles specific clicks', () => {
      triggerVisibility(true);
      const clickTarget = getDiffElement().querySelector('[data-click=foo]');
      delegatedClick(clickTarget);
      expect(adapter.clicks.foo).toHaveBeenCalledWith(expect.any(MouseEvent), clickTarget);
      expect(adapter.clicks.foo.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles visible event', () => {
      triggerVisibility(true);
      expect(adapter[VISIBLE]).toHaveBeenCalled();
      expect(adapter[VISIBLE].mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles invisible event', () => {
      triggerVisibility(false);
      expect(adapter[INVISIBLE]).toHaveBeenCalled();
      expect(adapter[INVISIBLE].mock.instances[0]).toStrictEqual(getContext());
    });
  });

  describe('static methods', () => {
    it('#findByFileHash', () => {
      expect(DiffFile.findByFileHash('fileHash')).toBeInstanceOf(DiffFile);
    });

    it('#getAll', () => {
      document.body.innerHTML = `
        <diff-file data-file-data="{}"><div></div></diff-file>
        <diff-file data-file-data="{}"><div></div></diff-file>
      `;
      const instances = DiffFile.getAll();
      expect(instances).toHaveLength(2);
      instances.forEach((instance) => expect(instance).toBeInstanceOf(DiffFile));
      // properly run destruction callbacks
      instances.forEach((instance) => instance.mount(app));
    });
  });
});
