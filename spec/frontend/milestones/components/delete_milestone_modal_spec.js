import Vue from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import mountComponent from 'helpers/vue_mount_component_helper';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import deleteMilestoneModal from '~/milestones/components/delete_milestone_modal.vue';
import eventHub from '~/milestones/event_hub';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  redirectTo: jest.fn(),
}));

describe('delete_milestone_modal.vue', () => {
  const Component = Vue.extend(deleteMilestoneModal);
  const props = {
    issueCount: 1,
    mergeRequestCount: 2,
    milestoneId: 3,
    milestoneTitle: 'my milestone title',
    milestoneUrl: `${TEST_HOST}/delete_milestone_modal.vue/milestone`,
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('onSubmit', () => {
    beforeEach(() => {
      vm = mountComponent(Component, props);
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('deletes milestone and redirects to overview page', async () => {
      const responseURL = `${TEST_HOST}/delete_milestone_modal.vue/milestoneOverview`;
      jest.spyOn(axios, 'delete').mockImplementation((url) => {
        expect(url).toBe(props.milestoneUrl);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          'deleteMilestoneModal.requestStarted',
          props.milestoneUrl,
        );
        eventHub.$emit.mockReset();
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });

      await vm.onSubmit();
      expect(redirectTo).toHaveBeenCalledWith(responseURL);
      expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestFinished', {
        milestoneUrl: props.milestoneUrl,
        successful: true,
      });
    });

    it('displays error if deleting milestone failed', async () => {
      const dummyError = new Error('deleting milestone failed');
      dummyError.response = { status: 418 };
      jest.spyOn(axios, 'delete').mockImplementation((url) => {
        expect(url).toBe(props.milestoneUrl);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          'deleteMilestoneModal.requestStarted',
          props.milestoneUrl,
        );
        eventHub.$emit.mockReset();
        return Promise.reject(dummyError);
      });

      await expect(vm.onSubmit()).rejects.toEqual(dummyError);
      expect(redirectTo).not.toHaveBeenCalled();
      expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestFinished', {
        milestoneUrl: props.milestoneUrl,
        successful: false,
      });
    });
  });

  describe('text', () => {
    it('contains the issue and milestone count', () => {
      vm = mountComponent(Component, props);
      const value = vm.text;

      expect(value).toContain('remove it from 1 issue and 2 merge requests');
    });

    it('contains neither issue nor milestone count', () => {
      vm = mountComponent(Component, {
        ...props,
        issueCount: 0,
        mergeRequestCount: 0,
      });

      const value = vm.text;

      expect(value).toContain('is not currently used');
    });
  });
});
