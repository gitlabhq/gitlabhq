import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemPrefetch from '~/work_items/components/work_item_prefetch.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { workItemByIidResponseFactory } from '../mock_data';

jest.mock('~/lib/utils/common_utils');

describe('WorkItemPrefetch component', () => {
  let wrapper;

  const getWorkItemQueryHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
  const findPrefetchTrigger = () => wrapper.findByTestId('prefetch-trigger');

  Vue.use(VueApollo);

  const createComponent = (workItemFullPath = undefined) => {
    const mockApollo = createMockApollo([[workItemByIidQuery, getWorkItemQueryHandler]]);

    wrapper = shallowMountExtended(WorkItemPrefetch, {
      apolloProvider: mockApollo,
      provide: {
        fullPath: 'group/project',
      },
      propsData: {
        workItemIid: '1',
        workItemFullPath,
      },
      scopedSlots: {
        default: `
          <span
            @mouseover="props.prefetchWorkItem"
            @mouseleave="props.clearPrefetching"
            data-testid="prefetch-trigger"
          >
            Hover item
          </span>
        `,
      },
    });
  };

  const triggerQuery = async () => {
    await findPrefetchTrigger().trigger('mouseover');

    await waitForPromises();
    await jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  };

  it('triggers prefetching on hover', async () => {
    createComponent();

    await triggerQuery();

    expect(getWorkItemQueryHandler).toHaveBeenCalled();
  });

  it('clears prefetching on mouseleave', async () => {
    createComponent();

    await findPrefetchTrigger().trigger('mouseover');
    await findPrefetchTrigger().trigger('mouseleave');

    expect(getWorkItemQueryHandler).not.toHaveBeenCalled();
  });

  describe('fullPath handling', () => {
    it('uses the injected fullPath if no workItemFullPath prop is provided', async () => {
      createComponent();

      await triggerQuery();

      expect(getWorkItemQueryHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '1' });
    });

    it('uses the workItemFullPath prop when provided', async () => {
      createComponent('other-full-path');

      await triggerQuery();

      expect(getWorkItemQueryHandler).toHaveBeenCalledWith({
        fullPath: 'other-full-path',
        iid: '1',
      });
    });
  });
});
