import { GlSprintf, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import DeleteMilestoneModal from '~/milestones/components/delete_milestone_modal.vue';
import eventHub from '~/milestones/event_hub';
import { HTTP_STATUS_IM_A_TEAPOT, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('Delete milestone modal', () => {
  let wrapper;
  const mockProps = {
    issueCount: 1,
    mergeRequestCount: 2,
    milestoneId: 3,
    milestoneTitle: 'my milestone title',
    milestoneUrl: `${TEST_HOST}/delete_milestone_modal.vue/milestone`,
  };

  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = (props) => {
    wrapper = shallowMount(DeleteMilestoneModal, {
      propsData: {
        ...mockProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('onSubmit', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('deletes milestone and redirects to overview page', async () => {
      const responseURL = `${TEST_HOST}/delete_milestone_modal.vue/milestoneOverview`;
      jest.spyOn(axios, 'delete').mockImplementation((url) => {
        expect(url).toBe(mockProps.milestoneUrl);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          'deleteMilestoneModal.requestStarted',
          mockProps.milestoneUrl,
        );
        eventHub.$emit.mockReset();
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });
      await findModal().vm.$emit('primary');
      expect(visitUrl).toHaveBeenCalledWith(responseURL);
      expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestFinished', {
        milestoneUrl: mockProps.milestoneUrl,
        successful: true,
      });
    });

    it.each`
      statusCode                 | alertMessage
      ${HTTP_STATUS_IM_A_TEAPOT} | ${`Failed to delete milestone ${mockProps.milestoneTitle}`}
      ${HTTP_STATUS_NOT_FOUND}   | ${`Milestone ${mockProps.milestoneTitle} was not found`}
    `(
      'displays error if deleting milestone failed with code $statusCode',
      async ({ statusCode, alertMessage }) => {
        const dummyError = new Error('deleting milestone failed');
        dummyError.response = { status: statusCode };
        jest.spyOn(axios, 'delete').mockImplementation((url) => {
          expect(url).toBe(mockProps.milestoneUrl);
          expect(eventHub.$emit).toHaveBeenCalledWith(
            'deleteMilestoneModal.requestStarted',
            mockProps.milestoneUrl,
          );
          eventHub.$emit.mockReset();
          return Promise.reject(dummyError);
        });

        await expect(wrapper.vm.onSubmit()).rejects.toEqual(dummyError);
        expect(createAlert).toHaveBeenCalledWith({
          message: alertMessage,
        });
        expect(visitUrl).not.toHaveBeenCalled();
        expect(eventHub.$emit).toHaveBeenCalledWith('deleteMilestoneModal.requestFinished', {
          milestoneUrl: mockProps.milestoneUrl,
          successful: false,
        });
      },
    );
  });

  describe('Modal title and description', () => {
    const emptyDescription = `You’re about to permanently delete the milestone ${mockProps.milestoneTitle}. This milestone is not currently used in any issues or merge requests.`;
    const description = `You’re about to permanently delete the milestone ${mockProps.milestoneTitle} and remove it from 1 issue and 2 merge requests. Once deleted, it cannot be undone or recovered.`;
    const title = `Delete milestone ${mockProps.milestoneTitle}?`;

    it('renders proper title', () => {
      const value = findModal().props('title');
      expect(value).toBe(title);
    });

    it.each`
      statement                         | descriptionText     | issueCount | mergeRequestCount
      ${'1 issue and 2 merge requests'} | ${description}      | ${1}       | ${2}
      ${'no issues and merge requests'} | ${emptyDescription} | ${0}       | ${0}
    `(
      'renders proper description when the milestone contains $statement',
      ({ issueCount, mergeRequestCount, descriptionText }) => {
        createComponent({
          issueCount,
          mergeRequestCount,
        });

        const value = findModal().text();
        expect(value).toBe(descriptionText);
      },
    );
  });
});
