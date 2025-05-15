import { DiffFile } from '~/rapid_diffs/diff_file';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';

describe('DiffFile Web Component', () => {
  const fileData = JSON.stringify({ viewer: 'current', custom: 'bar' });
  const html = `
    <diff-file data-file-data='${fileData}' id="fileHash">
      <div id="foo">
        <button data-click="foo"></button>
      </div>
    </diff-file>
  `;
  let app;
  let defaultAdapter;

  const getDiffElement = () => document.querySelector('[id=foo]');
  const getWebComponentElement = () => document.querySelector('diff-file');

  const triggerVisibility = (isIntersecting) => {
    const target = getWebComponentElement();
    // eslint-disable-next-line no-unused-expressions
    isIntersecting ? target.onVisible({}) : target.onInvisible({});
  };

  const createDefaultAdapter = (customAdapter) => {
    defaultAdapter = customAdapter;
  };

  const initRapidDiffsApp = (adapterConfig = { current: [defaultAdapter] }, appData = {}) => {
    app = {
      adapterConfig,
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

  const mount = () => {
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
    trigger: getWebComponentElement().trigger,
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    createDefaultAdapter({
      click: jest.fn(),
      clicks: {
        foo: jest.fn(),
      },
      visible: jest.fn(),
      invisible: jest.fn(),
      mounted: jest.fn(),
    });
    initRapidDiffsApp();
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
    expect(defaultAdapter.mounted).toHaveBeenCalled();
    expect(defaultAdapter.mounted.mock.instances[0]).toStrictEqual(getContext());
    expect(emitted).toBe(true);
  });

  it('properly unmounts', () => {
    mount();
    const element = getWebComponentElement();
    document.body.innerHTML = '';
    expect(app.unobserve).toHaveBeenCalledWith(element);
  });

  it('#selectFile', () => {
    mount();
    const spy = jest.spyOn(getWebComponentElement(), 'scrollIntoView');
    getWebComponentElement().selectFile();
    expect(spy).toHaveBeenCalled();
  });

  describe('when visible', () => {
    beforeEach(() => {
      mount();
    });

    it('handles all clicks', () => {
      triggerVisibility(true);
      delegatedClick(getDiffElement());
      expect(defaultAdapter.click).toHaveBeenCalledWith(expect.any(MouseEvent));
      expect(defaultAdapter.click.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles specific clicks', () => {
      triggerVisibility(true);
      const clickTarget = getDiffElement().querySelector('[data-click=foo]');
      delegatedClick(clickTarget);
      expect(defaultAdapter.clicks.foo).toHaveBeenCalledWith(expect.any(MouseEvent), clickTarget);
      expect(defaultAdapter.clicks.foo.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles visible event', () => {
      triggerVisibility(true);
      expect(defaultAdapter.visible).toHaveBeenCalled();
      expect(defaultAdapter.visible.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles invisible event', () => {
      triggerVisibility(false);
      expect(defaultAdapter.invisible).toHaveBeenCalled();
      expect(defaultAdapter.invisible.mock.instances[0]).toStrictEqual(getContext());
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
      expect(instances.length).toBe(2);
      instances.forEach((instance) => expect(instance).toBeInstanceOf(DiffFile));
      // properly run destruction callbacks
      instances.forEach((instance) => instance.mount(app));
    });
  });
});
