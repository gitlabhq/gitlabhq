import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableEditActions from '~/issues/show/components/edit_actions.vue';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import eventHub from '~/issues/show/event_hub';
import {
  getIssueStateQueryResponse,
  updateIssueStateQueryResponse,
} from '../mock_data/apollo_mock';

describe('Edit Actions component', () => {
  let wrapper;
  let fakeApollo;
  let mockIssueStateData;

  Vue.use(VueApollo);

  const mockResolvers = {
    Query: {
      issueState() {
        return {
          __typename: 'IssueState',
          rawData: mockIssueStateData(),
        };
      },
    },
  };

  const modalId = 'delete-issuable-modal-1';

  const createComponent = ({ props, data } = {}) => {
    fakeApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMountExtended(IssuableEditActions, {
      apolloProvider: fakeApollo,
      propsData: {
        formState: {
          title: 'GitLab Issue',
        },
        canDestroy: true,
        endpoint: 'gitlab-org/gitlab-test/-/issues/1',
        issuableType: 'issue',
        ...props,
      },
      data() {
        return {
          issueState: {},
          modalId,
          ...data,
        };
      },
    });
  };

  const findModal = () => wrapper.findComponent(DeleteIssueModal);
  const findEditButtons = () => wrapper.findAllComponents(GlButton);
  const findDeleteButton = () => wrapper.findByTestId('issuable-delete-button');
  const findSaveButton = () => wrapper.findByTestId('issuable-save-button');
  const findCancelButton = () => wrapper.findByTestId('issuable-cancel-button');

  beforeEach(() => {
    mockIssueStateData = jest.fn();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders all buttons as enabled', () => {
    const buttons = findEditButtons().wrappers;
    buttons.forEach((button) => {
      expect(button.attributes('disabled')).toBeUndefined();
    });
  });

  it('does not render the delete button if canDestroy is false', () => {
    createComponent({ props: { canDestroy: false } });
    expect(findDeleteButton().exists()).toBe(false);
  });

  it('disables save button when title is blank', () => {
    createComponent({ props: { formState: { title: '', issue_type: '' } } });

    expect(findSaveButton().attributes('disabled')).toBe('true');
  });

  it('does not render the delete button if showDeleteButton is false', () => {
    createComponent({ props: { showDeleteButton: false } });

    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('updateIssuable', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('sends update.issauble event when clicking save button', () => {
      findSaveButton().vm.$emit('click', { preventDefault: jest.fn() });

      expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
    });
  });

  describe('closeForm', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('emits close.form when clicking cancel', () => {
      findCancelButton().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('close.form');
    });
  });

  describe('delete issue button', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('tracks clicking on button', () => {
      findDeleteButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'delete_issue',
      });
    });
  });

  describe('delete issue modal', () => {
    it('renders', () => {
      expect(findModal().props()).toEqual({
        issuePath: 'gitlab-org/gitlab-test/-/issues/1',
        issueType: 'Issue',
        modalId,
        title: 'Delete issue',
      });
    });
  });

  describe('deleteIssuable', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('does not send the `delete.issuable` event when clicking delete button', () => {
      findDeleteButton().vm.$emit('click');
      expect(eventHub.$emit).not.toHaveBeenCalled();
    });

    it('sends the `delete.issuable` event when clicking the delete confirm button', async () => {
      expect(eventHub.$emit).toHaveBeenCalledTimes(0);
      findModal().vm.$emit('delete');
      expect(eventHub.$emit).toHaveBeenCalledWith('delete.issuable');
      expect(eventHub.$emit).toHaveBeenCalledTimes(1);
    });
  });

  describe('with Apollo cache mock', () => {
    it('renders the right delete button text per apollo cache type', async () => {
      mockIssueStateData.mockResolvedValue(getIssueStateQueryResponse);
      await waitForPromises();
      expect(findDeleteButton().text()).toBe('Delete issue');
    });

    it('should not change the delete button text per apollo cache mutation', async () => {
      mockIssueStateData.mockResolvedValue(updateIssueStateQueryResponse);
      await waitForPromises();
      expect(findDeleteButton().text()).toBe('Delete issue');
    });
  });
});
