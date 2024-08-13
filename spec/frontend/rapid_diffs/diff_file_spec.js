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
  const html = `<diff-file data-viewer="current"><div id="foo"></div></diff-file>`;
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
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    document.body.innerHTML = html;
    getWebComponentElement().mount();
  });

  it('observes diff element', () => {
    expect(IS.prototype.observe).toHaveBeenCalledWith(getWebComponentElement());
  });

  describe('when visible', () => {
    beforeEach(() => {
      assignAdapter({
        onClick: jest.fn(),
        onVisible: jest.fn(),
        onInvisible: jest.fn(),
      });
    });

    it('handles clicks', () => {
      triggerVisibility(true);
      getDiffElement().click();
      expect(adapter.onClick).toHaveBeenCalledWith(expect.any(MouseEvent));
      expect(adapter.onClick.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles visible event', () => {
      triggerVisibility(true);
      expect(adapter.onVisible).toHaveBeenCalled();
      expect(adapter.onVisible.mock.instances[0]).toStrictEqual(getContext());
    });

    it('handles invisible event', () => {
      triggerVisibility(false);
      expect(adapter.onInvisible).toHaveBeenCalled();
      expect(adapter.onInvisible.mock.instances[0]).toStrictEqual(getContext());
    });
  });
});
