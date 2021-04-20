import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { mount } from '@vue/test-utils';
import ensureData from '~/ensure_data';

const mockData = { message: 'Hello there' };
const defaultOptions = {
  parseData: () => mockData,
  data: mockData,
};

const MockChildComponent = {
  inject: ['message'],
  render(createElement) {
    return createElement('h1', this.message);
  },
};

const MockParentComponent = {
  components: {
    MockChildComponent,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
    otherProp: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  render(createElement) {
    return createElement('div', [this.message, createElement(MockChildComponent)]);
  },
};

describe('EnsureData', () => {
  let wrapper;

  function findEmptyState() {
    return wrapper.findComponent(GlEmptyState);
  }

  function findChild() {
    return wrapper.findComponent(MockChildComponent);
  }
  function findParent() {
    return wrapper.findComponent(MockParentComponent);
  }

  function createComponent(options = defaultOptions) {
    return mount(ensureData(MockParentComponent, options));
  }

  beforeEach(() => {
    Sentry.captureException = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    Sentry.captureException.mockClear();
  });

  describe('when parseData throws', () => {
    it('should render GlEmptyState', () => {
      wrapper = createComponent({
        parseData: () => {
          throw new Error();
        },
      });

      expect(findParent().exists()).toBe(false);
      expect(findChild().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });

    it('should not log to Sentry when shouldLog=false (default)', () => {
      wrapper = createComponent({
        parseData: () => {
          throw new Error();
        },
      });

      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('should log to Sentry when shouldLog=true', () => {
      const error = new Error('Error!');
      wrapper = createComponent({
        parseData: () => {
          throw error;
        },
        shouldLog: true,
      });

      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('when parseData succeeds', () => {
    it('should render MockParentComponent and MockChildComponent', () => {
      wrapper = createComponent();

      expect(findEmptyState().exists()).toBe(false);
      expect(findParent().exists()).toBe(true);
      expect(findChild().exists()).toBe(true);
    });

    it('enables user to provide data to child components', () => {
      wrapper = createComponent();

      const childComponent = findChild();
      expect(childComponent.text()).toBe(mockData.message);
    });

    it('enables user to override provide data', () => {
      const message = 'Another message';
      wrapper = createComponent({ ...defaultOptions, provide: { message } });

      const childComponent = findChild();
      expect(childComponent.text()).toBe(message);
    });

    it('enables user to pass props to parent component', () => {
      wrapper = createComponent();

      expect(findParent().props()).toMatchObject(mockData);
    });

    it('enables user to override props data', () => {
      const props = { message: 'Another message', otherProp: true };
      wrapper = createComponent({ ...defaultOptions, props });

      expect(findParent().props()).toMatchObject(props);
    });

    it('should not log to Sentry when shouldLog=true', () => {
      wrapper = createComponent({ ...defaultOptions, shouldLog: true });

      expect(Sentry.captureException).not.toHaveBeenCalled();
    });
  });
});
