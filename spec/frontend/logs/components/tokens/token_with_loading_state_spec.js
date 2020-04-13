import { GlFilteredSearchToken, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import TokenWithLoadingState from '~/logs/components/tokens/token_with_loading_state.vue';

describe('TokenWithLoadingState', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const initWrapper = (props = {}, options) => {
    wrapper = shallowMount(TokenWithLoadingState, {
      propsData: props,
      ...options,
    });
  };

  beforeEach(() => {});

  it('passes entire config correctly', () => {
    const config = {
      icon: 'pod',
      type: 'pod',
      title: 'Pod name',
      unique: true,
    };

    initWrapper({ config });

    expect(findFilteredSearchToken().props('config')).toEqual(config);
  });

  describe('suggestions are replaced', () => {
    let mockNoOptsText;
    let config;
    let stubs;

    beforeEach(() => {
      mockNoOptsText = 'No suggestions available';
      config = {
        loading: false,
        noOptionsText: mockNoOptsText,
      };
      stubs = {
        GlFilteredSearchToken: {
          template: `<div><slot name="suggestions"></slot></div>`,
        },
      };
    });

    it('renders a loading icon', () => {
      config.loading = true;

      initWrapper({ config }, { stubs });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(wrapper.text()).toBe('');
    });

    it('renders an empty results message', () => {
      initWrapper({ config }, { stubs });

      expect(findLoadingIcon().exists()).toBe(false);
      expect(wrapper.text()).toBe(mockNoOptsText);
    });
  });
});
