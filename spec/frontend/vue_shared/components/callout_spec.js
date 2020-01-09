import { shallowMount } from '@vue/test-utils';
import Callout from '~/vue_shared/components/callout.vue';

const TEST_MESSAGE = 'This is a callout message!';
const TEST_SLOT = '<button>This is a callout slot!</button>';

describe('Callout Component', () => {
  let wrapper;

  const factory = options => {
    wrapper = shallowMount(Callout, {
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render the appropriate variant of callout', () => {
    factory({
      propsData: {
        category: 'info',
        message: TEST_MESSAGE,
      },
    });

    expect(wrapper.classes()).toEqual(['bs-callout', 'bs-callout-info']);

    expect(wrapper.element.tagName).toEqual('DIV');
  });

  it('should render accessibility attributes', () => {
    factory({
      propsData: {
        message: TEST_MESSAGE,
      },
    });

    expect(wrapper.attributes('role')).toEqual('alert');
    expect(wrapper.attributes('aria-live')).toEqual('assertive');
  });

  it('should render the provided message', () => {
    factory({
      propsData: {
        message: TEST_MESSAGE,
      },
    });

    expect(wrapper.element.innerHTML.trim()).toEqual(TEST_MESSAGE);
  });

  it('should render the provided slot', () => {
    factory({
      slots: {
        default: TEST_SLOT,
      },
    });

    expect(wrapper.element.innerHTML.trim()).toEqual(TEST_SLOT);
  });
});
