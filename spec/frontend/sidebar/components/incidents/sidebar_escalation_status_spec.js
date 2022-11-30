import { createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import {
  fetchData,
  fetchError,
  mutationData,
  mutationError,
} from 'ee_else_ce_jest/sidebar/components/incidents/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SidebarEscalationStatus from '~/sidebar/components/incidents/sidebar_escalation_status.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import {
  escalationStatusQuery,
  escalationStatusMutation,
  STATUS_ACKNOWLEDGED,
} from '~/sidebar/constants';
import waitForPromises from 'helpers/wait_for_promises';
import EscalationStatus from 'ee_else_ce/sidebar/components/incidents/escalation_status.vue';
import { createAlert } from '~/flash';
import { logError } from '~/lib/logger';

jest.mock('~/lib/logger');
jest.mock('~/flash');

const localVue = createLocalVue();

describe('SidebarEscalationStatus', () => {
  let wrapper;
  const queryResolverMock = jest.fn();
  const mutationResolverMock = jest.fn();

  function createMockApolloProvider({ hasFetchError = false, hasMutationError = false } = {}) {
    localVue.use(VueApollo);

    queryResolverMock.mockResolvedValue({ data: hasFetchError ? fetchError : fetchData });
    mutationResolverMock.mockResolvedValue({
      data: hasMutationError ? mutationError : mutationData,
    });

    const requestHandlers = [
      [escalationStatusQuery, queryResolverMock],
      [escalationStatusMutation, mutationResolverMock],
    ];

    return createMockApollo(requestHandlers);
  }

  function createComponent({ mockApollo } = {}) {
    let config;

    if (mockApollo) {
      config = { apolloProvider: mockApollo };
    } else {
      config = { mocks: { $apollo: { queries: { status: { loading: false } } } } };
    }

    wrapper = mountExtended(SidebarEscalationStatus, {
      propsData: {
        iid: '1',
        projectPath: 'gitlab-org/gitlab',
        issuableType: 'issue',
      },
      provide: {
        canUpdate: true,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
      localVue,
      ...config,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findSidebarComponent = () => wrapper.findComponent(SidebarEditableItem);
  const findStatusComponent = () => wrapper.findComponent(EscalationStatus);
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findIcon = () => wrapper.findByTestId('status-icon');

  const clickEditButton = async () => {
    findEditButton().vm.$emit('click');
    await nextTick();
  };
  const selectAcknowledgedStatus = async () => {
    findStatusComponent().vm.$emit('input', STATUS_ACKNOWLEDGED);
    // wait for apollo requests
    await waitForPromises();
  };

  describe('sidebar', () => {
    it('renders the sidebar component', () => {
      createComponent();
      expect(findSidebarComponent().exists()).toBe(true);
    });

    describe('status icon', () => {
      it('is visible', () => {
        createComponent();

        expect(findIcon().exists()).toBe(true);
        expect(findIcon().isVisible()).toBe(true);
      });

      it('has correct tooltip', async () => {
        const mockApollo = createMockApolloProvider();
        createComponent({ mockApollo });

        // wait for apollo requests
        await waitForPromises();

        const tooltip = getBinding(findIcon().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Status: Triggered');
      });
    });

    describe('status dropdown', () => {
      beforeEach(async () => {
        const mockApollo = createMockApolloProvider();
        createComponent({ mockApollo });

        // wait for apollo requests
        await waitForPromises();
      });

      it('is closed by default', () => {
        expect(findStatusComponent().exists()).toBe(true);
        expect(findStatusComponent().isVisible()).toBe(false);
      });

      it('is shown after clicking the edit button', async () => {
        await clickEditButton();

        expect(findStatusComponent().isVisible()).toBe(true);
      });

      it('is hidden after clicking the edit button, when open already', async () => {
        await clickEditButton();
        await clickEditButton();

        expect(findStatusComponent().isVisible()).toBe(false);
      });
    });

    describe('update Status event', () => {
      beforeEach(async () => {
        const mockApollo = createMockApolloProvider();
        createComponent({ mockApollo });

        // wait for apollo requests
        await waitForPromises();

        await clickEditButton();
        await selectAcknowledgedStatus();
      });

      it('calls the mutation', () => {
        const mutationVariables = {
          iid: '1',
          projectPath: 'gitlab-org/gitlab',
          status: STATUS_ACKNOWLEDGED,
        };

        expect(mutationResolverMock).toHaveBeenCalledWith(mutationVariables);
      });

      it('closes the dropdown', () => {
        expect(findStatusComponent().isVisible()).toBe(false);
      });

      it('updates the status', () => {
        // Sometimes status has a intermediate wrapping component. A quirk of vue-test-utils
        // means that in that case 'value' is exposed as a prop. If no wrapping component
        // exists it is exposed as an attribute.
        const statusValue =
          findStatusComponent().props('value') || findStatusComponent().attributes('value');
        expect(statusValue).toBe(STATUS_ACKNOWLEDGED);
      });
    });

    describe('mutation errors', () => {
      it('should error upon fetch', async () => {
        const mockApollo = createMockApolloProvider({ hasFetchError: true });
        createComponent({ mockApollo });

        // wait for apollo requests
        await waitForPromises();

        expect(createAlert).toHaveBeenCalled();
        expect(logError).toHaveBeenCalled();
      });

      it('should error upon mutation', async () => {
        const mockApollo = createMockApolloProvider({ hasMutationError: true });
        createComponent({ mockApollo });

        // wait for apollo requests
        await waitForPromises();

        await clickEditButton();
        await selectAcknowledgedStatus();

        expect(createAlert).toHaveBeenCalled();
        expect(logError).toHaveBeenCalled();
      });
    });
  });
});
