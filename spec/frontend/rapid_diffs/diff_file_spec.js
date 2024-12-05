import { DiffFile } from '~/rapid_diffs/diff_file';
import IS from '~/rapid_diffs/intersection_observer';

// We have to use var here because jest hoists mock calls, so let would be uninitialized at this point
// eslint-disable-next-line no-var
var trigger;
// We can't apply useMockIntersectionObserver here because IS is called immediately when DiffFile is imported
jest.mock('~/rapid_diffs/intersection_observer', () => {
  class Observer {
    constructor(callback) {
      trigger = callback;
    }
  }
  Observer.prototype.observe = jest.fn();
  return Observer;
});

describe('DiffFile Web Component', () => {
  const html = `
    <diff-file data-viewer="current" data-custom="bar" id="fileHash">
      <div id="foo">
        <button data-click="foo"></button>
      </div>
    </diff-file>
  `;
  let adapter;

  const getDiffElement = () => document.querySelector('[id=foo]');
  const getWebComponentElement = () => document.querySelector('diff-file');

  const triggerVisibility = (isIntersecting) =>
    trigger([{ isIntersecting, target: getWebComponentElement() }]);

  const assignAdapter = (customAdapter) => {
    adapter = customAdapter;
    getWebComponentElement().adapterConfig = { current: [customAdapter] };
  };

  const getContext = () => ({
    diffElement: getDiffElement(),
    viewer: 'current',
    data: {
      custom: 'bar',
    },
    sink: {},
    trigger: getWebComponentElement().trigger,
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    document.body.innerHTML = html;
    assignAdapter({
      click: jest.fn(),
      clicks: {
        foo: jest.fn(),
      },
      visible: jest.fn(),
      invisible: jest.fn(),
      mounted: jest.fn(),
    });
    getWebComponentElement().mount();
  });

  it('observes diff element', () => {
    expect(IS.prototype.observe).toHaveBeenCalledWith(getWebComponentElement());
  });

  it('triggers mounted event', () => {
    expect(adapter.mounted).toHaveBeenCalled();
    expect(adapter.mounted.mock.instances[0]).toStrictEqual(getContext());
  });

  describe('when visible', () => {
    it('handles all clicks', () => {
      triggerVisibility(true);
      getDiffElement().click();
      expect(adapter.click).toHaveBeenCalledWith(expect.any(MouseEvent));
      expect(adapter.click.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles specific clicks', () => {
      triggerVisibility(true);
      getDiffElement().querySelector('[data-click=foo]').click();
      expect(adapter.clicks.foo).toHaveBeenCalledWith(expect.any(MouseEvent));
      expect(adapter.clicks.foo.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles visible event', () => {
      triggerVisibility(true);
      expect(adapter.visible).toHaveBeenCalled();
      expect(adapter.visible.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles invisible event', () => {
      triggerVisibility(false);
      expect(adapter.invisible).toHaveBeenCalled();
      expect(adapter.invisible.mock.instances[0]).toStrictEqual(getContext());
    });
  });

  describe('static methods', () => {
    it('findByFileHash', () => {
      expect(DiffFile.findByFileHash('fileHash')).toBeInstanceOf(DiffFile);
    });

    it('getAll', () => {
      document.body.innerHTML = `<diff-file></diff-file><diff-file></diff-file>`;
      const instances = DiffFile.getAll();
      expect(instances.length).toBe(2);
      instances.forEach((instance) => expect(instance).toBeInstanceOf(DiffFile));
    });
  });
});
