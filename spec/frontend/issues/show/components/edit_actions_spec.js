import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuableEditActions from '~/issues/show/components/edit_actions.vue';
import eventHub from '~/issues/show/event_hub';

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
          ...data,
        };
      },
    });
  };

  const findEditButtons = () => wrapper.findAllComponents(GlButton);
  const findSaveButton = () => wrapper.findByTestId('issuable-save-button');
  const findCancelButton = () => wrapper.findByTestId('issuable-cancel-button');

  beforeEach(() => {
    mockIssueStateData = jest.fn();
    createComponent();
  });

  it('renders all buttons as enabled', () => {
    const buttons = findEditButtons().wrappers;
    buttons.forEach((button) => {
      expect(button.attributes('disabled')).toBeUndefined();
    });
  });

  it('disables save button when title is blank', () => {
    createComponent({ props: { formState: { title: '', issue_type: '' } } });

    expect(findSaveButton().attributes('disabled')).toBeDefined();
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
});
