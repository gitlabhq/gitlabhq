import {
  GlFilteredSearchToken,
  GlFilteredSearchTokenSegment,
  GlFilteredSearchSuggestion,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import IterationToken from '~/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import { mockIterationToken, mockIterations } from '../mock_data';

jest.mock('~/flash');

describe('IterationToken', () => {
  const id = 123;
  let wrapper;

  const createComponent = ({
    config = mockIterationToken,
    value = { data: '' },
    active = false,
    stubs = {},
    provide = {},
  } = {}) =>
    mount(IterationToken, {
      propsData: {
        active,
        config,
        value,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        ...provide,
      },
      stubs,
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when iteration cadence feature is available', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockIterationToken, initialIterations: mockIterations },
        value: { data: 'i' },
        stubs: { Portal: true },
        provide: {
          glFeatures: {
            iterationCadences: true,
          },
        },
      });

      await wrapper.setData({ loading: false });
    });

    it('renders iteration start date and due date', () => {
      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions.at(3).text()).toContain('Nov 5, 2021 - Nov 10, 2021');
    });
  });

  it('renders iteration value', async () => {
    wrapper = createComponent({ value: { data: id } });

    await wrapper.vm.$nextTick();

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Iteration` `=` `gitlab-org: #1`
    expect(tokenSegments.at(2).text()).toBe(id.toString());
  });

  it('fetches initial values', () => {
    const fetchIterationsSpy = jest.fn().mockResolvedValue();

    wrapper = createComponent({
      config: { ...mockIterationToken, fetchIterations: fetchIterationsSpy },
      value: { data: id },
    });

    expect(fetchIterationsSpy).toHaveBeenCalledWith(id);
  });

  it('fetches iterations on user input', () => {
    const search = 'hello';
    const fetchIterationsSpy = jest.fn().mockResolvedValue();

    wrapper = createComponent({
      config: { ...mockIterationToken, fetchIterations: fetchIterationsSpy },
    });

    wrapper.findComponent(GlFilteredSearchToken).vm.$emit('input', { data: search });

    expect(fetchIterationsSpy).toHaveBeenCalledWith(search);
  });

  it('renders error message when request fails', async () => {
    const fetchIterationsSpy = jest.fn().mockRejectedValue();

    wrapper = createComponent({
      config: { ...mockIterationToken, fetchIterations: fetchIterationsSpy },
    });

    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith({
      message: 'There was a problem fetching iterations.',
    });
  });
});
