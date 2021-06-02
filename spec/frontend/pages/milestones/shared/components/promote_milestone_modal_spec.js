import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import PromoteMilestoneModal from '~/pages/milestones/shared/components/promote_milestone_modal.vue';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/flash');

describe('Promote milestone modal', () => {
  let wrapper;
  const milestoneMockData = {
    milestoneTitle: 'v1.0',
    url: `${TEST_HOST}/dummy/promote/milestones`,
    groupName: 'group',
  };

  const promoteButton = () => document.querySelector('.js-promote-project-milestone-button');

  beforeEach(() => {
    setHTMLFixture(`<button
      class="js-promote-project-milestone-button"
      data-group-name="${milestoneMockData.groupName}"
      data-milestone-title="${milestoneMockData.milestoneTitle}"
      data-url="${milestoneMockData.url}">
      Promote
      </button>`);
    wrapper = shallowMount(PromoteMilestoneModal);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Modal opener button', () => {
    it('button gets disabled when the modal opens', () => {
      expect(promoteButton().disabled).toBe(false);

      promoteButton().click();

      expect(promoteButton().disabled).toBe(true);
    });

    it('button gets enabled when the modal closes', () => {
      promoteButton().click();

      wrapper.findComponent(GlModal).vm.$emit('hide');

      expect(promoteButton().disabled).toBe(false);
    });
  });

  describe('Modal title and description', () => {
    beforeEach(() => {
      promoteButton().click();
    });

    it('contains the proper description', () => {
      expect(wrapper.vm.text).toContain(
        `Promoting ${milestoneMockData.milestoneTitle} will make it available for all projects inside ${milestoneMockData.groupName}.`,
      );
    });

    it('contains the correct title', () => {
      expect(wrapper.vm.title).toBe('Promote v1.0 to group milestone?');
    });
  });

  describe('When requesting a milestone promotion', () => {
    beforeEach(() => {
      promoteButton().click();
    });

    it('redirects when a milestone is promoted', async () => {
      const responseURL = `${TEST_HOST}/dummy/endpoint`;
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(milestoneMockData.url);
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
      dummyError.response = { status: 500 };
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(milestoneMockData.url);
        return Promise.reject(dummyError);
      });

      wrapper.findComponent(GlModal).vm.$emit('primary');
      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({ message: dummyError });
    });
  });
});
