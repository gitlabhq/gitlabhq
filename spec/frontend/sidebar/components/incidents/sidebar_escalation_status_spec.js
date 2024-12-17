import Vue, { nextTick } from 'vue';
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
import { STATUS_ACKNOWLEDGED } from '~/sidebar/constants';
import { escalationStatusQuery, escalationStatusMutation } from '~/sidebar/queries/constants';
import waitForPromises from 'helpers/wait_for_promises';
import EscalationStatus from 'ee_else_ce/sidebar/components/incidents/escalation_status.vue';
import { createAlert } from '~/alert';
import { logError } from '~/lib/logger';

jest.mock('~/lib/logger');
jest.mock('~/alert');

Vue.use(VueApollo);

describe('SidebarEscalationStatus', () => {
  let wrapper;
  let mockApollo;
  const queryResolverMock = jest.fn();
  const mutationResolverMock = jest.fn();

  function createMockApolloProvider({ hasFetchError = false, hasMutationError = false } = {}) {
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

  function createComponent(apolloProvider) {
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
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      apolloProvider,
    });

    // wait for apollo requests
    return waitForPromises();
  }

  beforeEach(() => {
    mockApollo = createMockApolloProvider();
  });

  const findSidebarComponent = () => wrapper.findComponent(SidebarEditableItem);
  const findStatusComponent = () => wrapper.findComponent(EscalationStatus);
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findIcon = () => wrapper.findByTestId('status-icon');

  const clickEditButton = () => {
    findEditButton().vm.$emit('click');
    return nextTick();
  };
  const selectAcknowledgedStatus = () => {
    findStatusComponent().vm.$emit('input', STATUS_ACKNOWLEDGED);
    // wait for apollo requests
    return waitForPromises();
  };

  describe('sidebar', () => {
    it('renders the sidebar component', async () => {
      await createComponent(mockApollo);
      expect(findSidebarComponent().exists()).toBe(true);
    });

    describe('status icon', () => {
      it('is visible', async () => {
        await createComponent(mockApollo);

        expect(findIcon().exists()).toBe(true);
        expect(findIcon().isVisible()).toBe(true);
      });

      it('has correct tooltip', async () => {
        await createComponent(mockApollo);

        const tooltip = getBinding(findIcon().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Status: Triggered');
      });
    });

    describe('status dropdown', () => {
      beforeEach(async () => {
        await createComponent(mockApollo);
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
        await createComponent(mockApollo);

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
        const statusValue = findStatusComponent().props('value');
        expect(statusValue).toBe(STATUS_ACKNOWLEDGED);
      });
    });

    describe('mutation errors', () => {
      it('should error upon fetch', async () => {
        mockApollo = createMockApolloProvider({ hasFetchError: true });
        await createComponent(mockApollo);

        expect(createAlert).toHaveBeenCalled();
        expect(logError).toHaveBeenCalled();
      });

      it('should error upon mutation', async () => {
        mockApollo = createMockApolloProvider({ hasMutationError: true });
        await createComponent(mockApollo);

        await clickEditButton();
        await selectAcknowledgedStatus();

        expect(createAlert).toHaveBeenCalled();
        expect(logError).toHaveBeenCalled();
      });
    });
  });
});
