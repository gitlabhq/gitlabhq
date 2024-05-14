import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import * as urlUtils from '~/lib/utils/url_utility';
import PromoteMilestoneModal from '~/milestones/components/promote_milestone_modal.vue';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('Promote milestone modal', () => {
  let wrapper;
  const milestoneMockData = {
    milestoneTitle: 'v1.0',
    promoteUrl: `${TEST_HOST}/dummy/promote/milestones`,
    groupName: 'group',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(PromoteMilestoneModal, {
      propsData,
      stubs: {
        PromoteMilestoneModal,
      },
    });
  };

  describe('Modal title and description', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          visible: true,
          milestoneTitle: milestoneMockData.milestoneTitle,
          promoteUrl: milestoneMockData.promoteUrl,
          groupName: milestoneMockData.groupName,
        },
      });
    });

    it('contains the proper description', () => {
      expect(wrapper.vm.text).toContain(
        `Promoting ${milestoneMockData.milestoneTitle} will make it available for all projects inside ${milestoneMockData.groupName}.`,
      );
    });

    it('contains the correct title', () => {
      expect(wrapper.vm.title).toBe(
        `Promote ${milestoneMockData.milestoneTitle} to group milestone?`,
      );
    });
  });

  describe('When requesting a milestone promotion', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          visible: true,
          milestoneTitle: milestoneMockData.milestoneTitle,
          promoteUrl: milestoneMockData.promoteUrl,
          groupName: milestoneMockData.groupName,
        },
      });
    });

    it('redirects when a milestone is promoted', async () => {
      const responseURL = `${TEST_HOST}/dummy/endpoint`;
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(milestoneMockData.promoteUrl);
        return Promise.resolve({
          data: {
            url: responseURL,
          },
        });
      });

      wrapper.findComponent(GlModal).vm.$emit('primary');
      await waitForPromises();

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(responseURL);
    });

    it('displays an error if promoting a milestone failed', async () => {
      const dummyError = new Error('promoting milestone failed');
      dummyError.response = { status: HTTP_STATUS_INTERNAL_SERVER_ERROR };
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(milestoneMockData.promoteUrl);
        return Promise.reject(dummyError);
      });

      wrapper.findComponent(GlModal).vm.$emit('primary');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: dummyError });
    });
  });
});
