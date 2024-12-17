import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import Item from '~/ide/components/merge_requests/item.vue';
import List from '~/ide/components/merge_requests/list.vue';
import TokenedInput from '~/ide/components/shared/tokened_input.vue';
import { mergeRequests as mergeRequestsMock } from '../../mock_data';

Vue.use(Vuex);

const skipReason = new SkipReason({
  name: 'IDE merge requests list',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  let wrapper;
  let fetchMergeRequestsMock;

  const findSearchTypeButtons = () => wrapper.findAllComponents(GlButton);
  const findTokenedInput = () => wrapper.findComponent(TokenedInput);

  const createComponent = (state = {}) => {
    const { mergeRequests = {}, ...restOfState } = state;
    const fakeStore = new Vuex.Store({
      state: {
        currentMergeRequestId: '1',
        currentProjectId: 'project/main',
        ...restOfState,
      },
      modules: {
        mergeRequests: {
          namespaced: true,
          state: {
            isLoading: false,
            mergeRequests: [],
            ...mergeRequests,
          },
          actions: {
            fetchMergeRequests: fetchMergeRequestsMock,
          },
        },
      },
    });

    wrapper = shallowMount(List, {
      store: fakeStore,
    });
  };

  beforeEach(() => {
    fetchMergeRequestsMock = jest.fn();
  });

  it('calls fetch on mounted', () => {
    createComponent();
    expect(fetchMergeRequestsMock).toHaveBeenCalledWith(expect.any(Object), {
      search: '',
      type: '',
    });
  });

  it('renders loading icon when merge request is loading', () => {
    createComponent({ mergeRequests: { isLoading: true } });
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders no search results text when search is not empty', async () => {
    createComponent();
    findTokenedInput().vm.$emit('input', 'something');
    await nextTick();
    expect(wrapper.text()).toContain('No merge requests found');
  });

  it('clicking on search type, sets currentSearchType and loads merge requests', async () => {
    createComponent();
    findTokenedInput().vm.$emit('focus');

    await nextTick();
    await findSearchTypeButtons().at(0).vm.$emit('click');

    await nextTick();
    const searchType = wrapper.vm.$options.searchTypes[0];

    expect(findTokenedInput().props('tokens')).toEqual([searchType]);
    expect(fetchMergeRequestsMock).toHaveBeenCalledWith(expect.any(Object), {
      type: searchType.type,
      search: '',
    });
  });

  describe('with merge requests', () => {
    let defaultStateWithMergeRequests;

    beforeAll(() => {
      defaultStateWithMergeRequests = {
        mergeRequests: {
          isLoading: false,
          mergeRequests: [
            { ...mergeRequestsMock[0], projectPathWithNamespace: 'gitlab-org/gitlab-foss' },
          ],
        },
      };
    });

    it('renders list', () => {
      createComponent(defaultStateWithMergeRequests);

      expect(wrapper.findAllComponents(Item).length).toBe(1);
      expect(wrapper.findComponent(Item).props('item')).toBe(
        defaultStateWithMergeRequests.mergeRequests.mergeRequests[0],
      );
    });

    describe('when searching merge requests', () => {
      it('calls `loadMergeRequests` on input in search field', async () => {
        createComponent(defaultStateWithMergeRequests);
        const input = findTokenedInput();
        input.vm.$emit('input', 'something');

        await nextTick();
        expect(fetchMergeRequestsMock).toHaveBeenCalledWith(expect.any(Object), {
          search: 'something',
          type: '',
        });
      });
    });
  });

  describe('on search focus', () => {
    let input;

    beforeEach(() => {
      createComponent();
      input = findTokenedInput();
    });

    describe('without search value', () => {
      beforeEach(async () => {
        input.vm.$emit('focus');
        await nextTick();
      });

      it('shows search types', () => {
        const buttons = findSearchTypeButtons();
        expect(buttons.wrappers.map((x) => x.text().trim())).toEqual(
          wrapper.vm.$options.searchTypes.map((x) => x.label),
        );
      });

      it('hides search types when search changes', async () => {
        input.vm.$emit('input', 'something');

        await nextTick();
        expect(findSearchTypeButtons().exists()).toBe(false);
      });

      describe('with search type', () => {
        beforeEach(async () => {
          await findSearchTypeButtons().at(0).vm.$emit('click');

          await nextTick();
          await input.vm.$emit('focus');
          await nextTick();
        });

        it('does not show search types', () => {
          expect(findSearchTypeButtons().exists()).toBe(false);
        });
      });
    });

    describe('with search value', () => {
      beforeEach(async () => {
        input.vm.$emit('input', 'something');
        input.vm.$emit('focus');
        await nextTick();
      });

      it('does not show search types', () => {
        expect(findSearchTypeButtons().exists()).toBe(false);
      });
    });
  });
});
