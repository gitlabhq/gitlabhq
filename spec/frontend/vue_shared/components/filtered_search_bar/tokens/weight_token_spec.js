import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import WeightToken from '~/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';
import { mockWeightToken } from '../mock_data';

jest.mock('~/flash');

describe('WeightToken', () => {
  const weight = '3';
  let wrapper;

  const createComponent = ({ config = mockWeightToken, value = { data: '' } } = {}) =>
    mount(WeightToken, {
      propsData: {
        config,
        value,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: 'custom-class',
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders weight value', () => {
    wrapper = createComponent({ value: { data: weight } });

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Weight` `=` `3`
    expect(tokenSegments.at(2).text()).toBe(weight);
  });
});
