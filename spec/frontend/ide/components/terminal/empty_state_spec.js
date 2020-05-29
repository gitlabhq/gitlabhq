import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { TEST_HOST } from 'spec/test_constants';
import TerminalEmptyState from '~/ide/components/terminal/empty_state.vue';

const TEST_HELP_PATH = `${TEST_HOST}/help/test`;
const TEST_PATH = `${TEST_HOST}/home.png`;
const TEST_HTML_MESSAGE = 'lorem <strong>ipsum</strong>';

describe('IDE TerminalEmptyState', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(TerminalEmptyState, {
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not show illustration, if no path specified', () => {
    factory();

    expect(wrapper.find('.svg-content').exists()).toBe(false);
  });

  it('shows illustration with path', () => {
    factory({
      propsData: {
        illustrationPath: TEST_PATH,
      },
    });

    const img = wrapper.find('.svg-content img');

    expect(img.exists()).toBe(true);
    expect(img.attributes('src')).toEqual(TEST_PATH);
  });

  it('when loading, shows loading icon', () => {
    factory({
      propsData: {
        isLoading: true,
      },
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('when not loading, does not show loading icon', () => {
    factory({
      propsData: {
        isLoading: false,
      },
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
  });

  describe('when valid', () => {
    let button;

    beforeEach(() => {
      factory({
        propsData: {
          isLoading: false,
          isValid: true,
          helpPath: TEST_HELP_PATH,
        },
      });

      button = wrapper.find('button');
    });

    it('shows button', () => {
      expect(button.text()).toEqual('Start Web Terminal');
      expect(button.attributes('disabled')).toBeFalsy();
    });

    it('emits start when button is clicked', () => {
      expect(wrapper.emitted().start).toBeFalsy();

      button.trigger('click');

      expect(wrapper.emitted().start).toHaveLength(1);
    });

    it('shows help path link', () => {
      expect(wrapper.find('a').attributes('href')).toEqual(TEST_HELP_PATH);
    });
  });

  it('when not valid, shows disabled button and message', () => {
    factory({
      propsData: {
        isLoading: false,
        isValid: false,
        message: TEST_HTML_MESSAGE,
      },
    });

    expect(wrapper.find('button').attributes('disabled')).not.toBe(null);
    expect(wrapper.find('.bs-callout').element.innerHTML).toEqual(TEST_HTML_MESSAGE);
  });
});
