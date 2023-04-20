import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import RunnerCount from '~/ci/runner/components/stat/runner_count.vue';
import { INSTANCE_TYPE, GROUP_TYPE, STATUS_ONLINE } from '~/ci/runner/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';

import allRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners_count.query.graphql';
import groupRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/group_runners_count.query.graphql';

import { runnersCountData, groupRunnersCountData } from '../../mock_data';

jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('RunnerCount', () => {
  let wrapper;
  let mockRunnersCountHandler;
  let mockGroupRunnersCountHandler;

  const createComponent = ({ props = {}, ...options } = {}) => {
    const handlers = [
      [allRunnersCountQuery, mockRunnersCountHandler],
      [groupRunnersCountQuery, mockGroupRunnersCountHandler],
    ];

    wrapper = shallowMount(RunnerCount, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        ...props,
      },
      scopedSlots: {
        default: '<strong>{{props.count}}</strong>',
      },
      ...options,
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnersCountHandler = jest.fn().mockResolvedValue(runnersCountData);
    mockGroupRunnersCountHandler = jest.fn().mockResolvedValue(groupRunnersCountData);
  });

  describe('in admin scope', () => {
    const mockVariables = { status: STATUS_ONLINE };

    beforeEach(async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE } });
    });

    it('fetches data from admin query', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(1);
      expect(mockRunnersCountHandler).toHaveBeenCalledWith({});
    });

    it('fetches data with filters', async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE, variables: mockVariables } });

      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(2);
      expect(mockRunnersCountHandler).toHaveBeenCalledWith(mockVariables);

      expect(wrapper.html()).toBe(`<strong>${runnersCountData.data.runners.count}</strong>`);
    });

    it('does not fetch from the group query', () => {
      expect(mockGroupRunnersCountHandler).not.toHaveBeenCalled();
    });

    describe('when this query is skipped after data was loaded', () => {
      beforeEach(async () => {
        wrapper.setProps({ skip: true });

        await nextTick();
      });

      it('clears current data', () => {
        expect(wrapper.html()).toBe('<strong></strong>');
      });
    });
  });

  describe('when skipping query', () => {
    beforeEach(async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE, skip: true } });
    });

    it('does not fetch data', () => {
      expect(mockRunnersCountHandler).not.toHaveBeenCalled();
      expect(mockGroupRunnersCountHandler).not.toHaveBeenCalled();

      expect(wrapper.html()).toBe('<strong></strong>');
    });
  });

  describe('when runners query fails', () => {
    const mockError = new Error('error!');

    beforeEach(async () => {
      mockRunnersCountHandler.mockRejectedValue(mockError);

      await createComponent({ props: { scope: INSTANCE_TYPE } });
    });

    it('data is not shown and error is reported', () => {
      expect(wrapper.html()).toBe('<strong></strong>');

      expect(captureException).toHaveBeenCalledWith({
        component: 'RunnerCount',
        error: mockError,
      });
    });
  });

  describe('in group scope', () => {
    beforeEach(async () => {
      await createComponent({ props: { scope: GROUP_TYPE } });
    });

    it('fetches data from the group query', () => {
      expect(mockGroupRunnersCountHandler).toHaveBeenCalledTimes(1);
      expect(mockGroupRunnersCountHandler).toHaveBeenCalledWith({});

      expect(wrapper.html()).toBe(
        `<strong>${groupRunnersCountData.data.group.runners.count}</strong>`,
      );
    });

    it('does not fetch from the group query', () => {
      expect(mockRunnersCountHandler).not.toHaveBeenCalled();
    });
  });

  describe('when .refetch() is called', () => {
    beforeEach(async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE } });
      wrapper.vm.refetch();
    });

    it('data is not shown and error is reported', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(2);
    });
  });
});
