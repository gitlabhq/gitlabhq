import { GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import HeaderActionsConfidentialityToggle from '~/issues/show/components/header_actions_confidentiality_toggle.vue';
import issueConfidentialQuery from '~/sidebar/queries/issue_confidential.query.graphql';
import updateIssueConfidentialMutation from '~/sidebar/queries/update_issue_confidential.mutation.graphql';

jest.mock('~/alert', () => ({
  createAlert: jest.fn(),
}));

describe('HeaderActionsConfidentialityToggle', () => {
  let wrapper;
  let mockApollo;
  let mockMutation;

  Vue.use(VueApollo);

  const mockConfidentialityQueryResponse = {
    data: {
      workspace: {
        id: '1',
        issuable: {
          id: '1',
          confidential: false,
        },
      },
    },
  };

  const mockConfidentialityMutationResponse = {
    data: {
      issuableSetConfidential: {
        issuable: {
          id: '1',
          confidential: false,
        },
        errors: [],
      },
    },
  };

  const mockConfidentialityMutationErrorResponse = {
    data: {
      issuableSetConfidential: {
        issuable: {
          id: '1',
          confidential: false,
        },
        errors: ['An error occurred'],
      },
    },
  };

  const createComponent = ({ queryHandler, mutationHandler } = {}) => {
    mockMutation = mutationHandler;
    mockApollo = createMockApollo([
      [issueConfidentialQuery, queryHandler],
      [updateIssueConfidentialMutation, mockMutation],
    ]);

    wrapper = shallowMountExtended(HeaderActionsConfidentialityToggle, {
      apolloProvider: mockApollo,
      provide: {
        iid: '1',
        issuePath: 'gitlab-org/gitlab-test/-/issues/1',
        projectPath: 'gitlab-org/gitlab-test',
        fullPath: 'gitlab-org/gitlab-test',
        issueType: 'issue',
      },
      mocks: {
        $toast: {
          show: jest.fn(),
        },
      },
      stubs: {
        GlDisclosureDropdownItem,
      },
    });
  };

  it('renders the component', () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(mockConfidentialityQueryResponse),
    });

    expect(wrapper.findComponent(GlDisclosureDropdownItem).exists()).toBe(true);
  });

  it('toggles confidentiality successfully', async () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(mockConfidentialityQueryResponse),
      mutationHandler: jest.fn().mockResolvedValue(mockConfidentialityMutationResponse),
    });

    wrapper.findComponent(GlDisclosureDropdownItem).vm.$emit('action');

    await waitForPromises();

    expect(createAlert).not.toHaveBeenCalled();
    expect(mockMutation).toHaveBeenCalled();
  });

  it('shows an error alert when toggling confidentiality fails', async () => {
    createComponent({
      queryHandler: jest.fn().mockResolvedValue(mockConfidentialityQueryResponse),
      mutationHandler: jest.fn().mockResolvedValue(mockConfidentialityMutationErrorResponse),
    });

    wrapper.findComponent(GlDisclosureDropdownItem).vm.$emit('action');

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'An error occurred',
    });
    expect(mockMutation).toHaveBeenCalled();
  });
});
