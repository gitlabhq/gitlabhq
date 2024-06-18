import { GlDisclosureDropdown } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardOptions from '~/boards/components/board_options.vue';
import ToggleEpicsSwimlanes from 'ee_component/boards/components/toggle_epics_swimlanes.vue';

import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';

describe('BoardOptions component', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMountExtended(BoardOptions, {
      propsData: {
        showEpicLaneOption: true,
      },
    });
  });

  it('renders a GlDisclosureDropdown', () => {
    expect(wrapper.findComponent(GlDisclosureDropdown).exists()).toBe(true);
  });

  describe('Labels options', () => {
    Vue.use(VueApollo);

    const mockSetIsShowingLabelsResolver = jest.fn();

    const mockApollo = createMockApollo([], {
      Mutation: {
        setIsShowingLabels: mockSetIsShowingLabelsResolver,
      },
    });

    beforeEach(() => {
      mockApollo.clients.defaultClient.cache.writeQuery({
        query: isShowingLabelsQuery,
        data: {
          isShowingLabels: true,
        },
      });
      wrapper = shallowMountExtended(BoardOptions, {
        apolloProvider: mockApollo,
      });
    });

    it('renders toggle to show or hide labels', () => {
      expect(wrapper.findByTestId('show-labels-toggle').exists()).toBe(true);
    });
    it('sets isShowingLabels when toggled', async () => {
      const labelToggleDropdownItem = wrapper.findByTestId('show-labels-toggle-item');
      labelToggleDropdownItem.vm.$emit('action');
      await waitForPromises();

      expect(mockSetIsShowingLabelsResolver).toHaveBeenCalledWith(
        {},
        {
          isShowingLabels: false,
        },
        expect.anything(),
        expect.anything(),
      );
    });
  });

  describe('Epic swimlanes options', () => {
    it.each`
      shows                | expected
      ${'renders'}         | ${true}
      ${'does not render'} | ${false}
    `(
      '$shows ToggleEpicsSwimlanes component when showEpicLaneOption is $expected',
      ({ expected }) => {
        wrapper = shallowMountExtended(BoardOptions, {
          propsData: {
            showEpicLaneOption: expected,
          },
        });
        expect(wrapper.findComponent(ToggleEpicsSwimlanes).exists()).toBe(expected);
      },
    );
    it('emits toggleSwimlanes when toggled', () => {
      wrapper.findByTestId('epic-swimlanes-toggle-item').vm.$emit('action');
      expect(wrapper.emitted('toggleSwimlanes')).toHaveLength(1);
    });
  });
});
