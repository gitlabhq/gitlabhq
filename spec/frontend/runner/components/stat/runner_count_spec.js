import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import RunnerCount from '~/runner/components/stat/runner_count.vue';
import { INSTANCE_TYPE, GROUP_TYPE } from '~/runner/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/runner/sentry_utils';

import adminRunnersCountQuery from '~/runner/graphql/list/admin_runners_count.query.graphql';
import getGroupRunnersCountQuery from '~/runner/graphql/list/group_runners_count.query.graphql';

import { runnersCountData, groupRunnersCountData } from '../../mock_data';

jest.mock('~/runner/sentry_utils');

Vue.use(VueApollo);

describe('RunnerCount', () => {
  let wrapper;
  let mockRunnersCountQuery;
  let mockGroupRunnersCountQuery;

  const createComponent = ({ props = {}, ...options } = {}) => {
    const handlers = [
      [adminRunnersCountQuery, mockRunnersCountQuery],
      [getGroupRunnersCountQuery, mockGroupRunnersCountQuery],
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
    mockRunnersCountQuery = jest.fn().mockResolvedValue(runnersCountData);
    mockGroupRunnersCountQuery = jest.fn().mockResolvedValue(groupRunnersCountData);
  });

  describe('in admin scope', () => {
    const mockVariables = { status: 'ONLINE' };

    beforeEach(async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE } });
    });

    it('fetches data from admin query', () => {
      expect(mockRunnersCountQuery).toHaveBeenCalledTimes(1);
      expect(mockRunnersCountQuery).toHaveBeenCalledWith({});
    });

    it('fetches data with filters', async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE, variables: mockVariables } });

      expect(mockRunnersCountQuery).toHaveBeenCalledTimes(2);
      expect(mockRunnersCountQuery).toHaveBeenCalledWith(mockVariables);

      expect(wrapper.html()).toBe(`<strong>${runnersCountData.data.runners.count}</strong>`);
    });

    it('does not fetch from the group query', async () => {
      expect(mockGroupRunnersCountQuery).not.toHaveBeenCalled();
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

    it('does not fetch data', async () => {
      expect(mockRunnersCountQuery).not.toHaveBeenCalled();
      expect(mockGroupRunnersCountQuery).not.toHaveBeenCalled();

      expect(wrapper.html()).toBe('<strong></strong>');
    });
  });

  describe('when runners query fails', () => {
    const mockError = new Error('error!');

    beforeEach(async () => {
      mockRunnersCountQuery.mockRejectedValue(mockError);

      await createComponent({ props: { scope: INSTANCE_TYPE } });
    });

    it('data is not shown and error is reported', async () => {
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

    it('fetches data from the group query', async () => {
      expect(mockGroupRunnersCountQuery).toHaveBeenCalledTimes(1);
      expect(mockGroupRunnersCountQuery).toHaveBeenCalledWith({});

      expect(wrapper.html()).toBe(
        `<strong>${groupRunnersCountData.data.group.runners.count}</strong>`,
      );
    });

    it('does not fetch from the group query', () => {
      expect(mockRunnersCountQuery).not.toHaveBeenCalled();
    });
  });

  describe('when .refetch() is called', () => {
    beforeEach(async () => {
      await createComponent({ props: { scope: INSTANCE_TYPE } });
      wrapper.vm.refetch();
    });

    it('data is not shown and error is reported', async () => {
      expect(mockRunnersCountQuery).toHaveBeenCalledTimes(2);
    });
  });
});
