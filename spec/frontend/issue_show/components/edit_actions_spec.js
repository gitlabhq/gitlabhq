import { GlButton, GlModal } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableEditActions from '~/issue_show/components/edit_actions.vue';
import eventHub from '~/issue_show/event_hub';

import {
  getIssueStateQueryResponse,
  updateIssueStateQueryResponse,
} from '../mock_data/apollo_mock';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Edit Actions component', () => {
  let wrapper;
  let fakeApollo;
  let mockIssueStateData;

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

  async function deleteIssuable(localWrapper) {
    localWrapper.findComponent(GlModal).vm.$emit('primary');
  }

  const findModal = () => wrapper.findComponent(GlModal);
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
      expect(button.attributes('disabled')).toBeFalsy();
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

  describe('renders create modal with the correct information', () => {
    it('renders correct modal id', () => {
      expect(findModal().attributes('modalid')).toBe(modalId);
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
      await deleteIssuable(wrapper);
      expect(eventHub.$emit).toHaveBeenCalledWith('delete.issuable', { destroy_confirm: true });
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
