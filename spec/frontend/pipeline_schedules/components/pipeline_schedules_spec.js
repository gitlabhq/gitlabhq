import { GlAlert, GlLoadingIcon, GlModal, GlTabs } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { trimText } from 'helpers/text_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineSchedules from '~/pipeline_schedules/components/pipeline_schedules.vue';
import PipelineSchedulesTable from '~/pipeline_schedules/components/table/pipeline_schedules_table.vue';
import deletePipelineScheduleMutation from '~/pipeline_schedules/graphql/mutations/delete_pipeline_schedule.mutation.graphql';
import getPipelineSchedulesQuery from '~/pipeline_schedules/graphql/queries/get_pipeline_schedules.query.graphql';
import {
  mockGetPipelineSchedulesGraphQLResponse,
  mockPipelineScheduleNodes,
  deleteMutationResponse,
} from '../mock_data';

Vue.use(VueApollo);

describe('Pipeline schedules app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockGetPipelineSchedulesGraphQLResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const deleteMutationHandlerSuccess = jest.fn().mockResolvedValue(deleteMutationResponse);
  const deleteMutationHandlerFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createMockApolloProvider = (
    requestHandlers = [[getPipelineSchedulesQuery, successHandler]],
  ) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers) => {
    wrapper = mountExtended(PipelineSchedules, {
      provide: {
        fullPath: 'gitlab-org/gitlab',
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
    });
  };

  const findTable = () => wrapper.findComponent(PipelineSchedulesTable);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findModal = () => wrapper.findComponent(GlModal);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findNewButton = () => wrapper.findByTestId('new-schedule-button');
  const findAllTab = () => wrapper.findByTestId('pipeline-schedules-all-tab');
  const findActiveTab = () => wrapper.findByTestId('pipeline-schedules-active-tab');
  const findInactiveTab = () => wrapper.findByTestId('pipeline-schedules-inactive-tab');

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays table, tabs and new button', async () => {
    createComponent();

    await waitForPromises();

    expect(findTable().exists()).toBe(true);
    expect(findNewButton().exists()).toBe(true);
    expect(findTabs().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
  });

  it('fetches query and passes an array of pipeline schedules', async () => {
    createComponent();

    expect(successHandler).toHaveBeenCalled();

    await waitForPromises();

    expect(findTable().props('schedules')).toEqual(mockPipelineScheduleNodes);
  });

  it('handles loading state', async () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);

    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('shows query error alert', async () => {
    createComponent([[getPipelineSchedulesQuery, failedHandler]]);

    await waitForPromises();

    expect(findAlert().text()).toBe('There was a problem fetching pipeline schedules.');
  });

  it('shows delete mutation error alert', async () => {
    createComponent([
      [getPipelineSchedulesQuery, successHandler],
      [deletePipelineScheduleMutation, deleteMutationHandlerFailed],
    ]);

    await waitForPromises();

    findModal().vm.$emit('primary');

    await waitForPromises();

    expect(findAlert().text()).toBe('There was a problem deleting the pipeline schedule.');
  });

  it('deletes pipeline schedule and refetches query', async () => {
    createComponent([
      [getPipelineSchedulesQuery, successHandler],
      [deletePipelineScheduleMutation, deleteMutationHandlerSuccess],
    ]);

    jest.spyOn(wrapper.vm.$apollo.queries.schedules, 'refetch');

    await waitForPromises();

    const scheduleId = mockPipelineScheduleNodes[0].id;

    findTable().vm.$emit('showDeleteModal', scheduleId);

    expect(wrapper.vm.$apollo.queries.schedules.refetch).not.toHaveBeenCalled();

    findModal().vm.$emit('primary');

    await waitForPromises();

    expect(deleteMutationHandlerSuccess).toHaveBeenCalledWith({
      id: scheduleId,
    });
    expect(wrapper.vm.$apollo.queries.schedules.refetch).toHaveBeenCalled();
  });

  it('modal should be visible after event', async () => {
    createComponent();

    await waitForPromises();

    expect(findModal().props('visible')).toBe(false);

    findTable().vm.$emit('showDeleteModal', mockPipelineScheduleNodes[0].id);

    await nextTick();

    expect(findModal().props('visible')).toBe(true);
  });

  it('modal should be hidden', async () => {
    createComponent();

    await waitForPromises();

    findTable().vm.$emit('showDeleteModal', mockPipelineScheduleNodes[0].id);

    await nextTick();

    expect(findModal().props('visible')).toBe(true);

    findModal().vm.$emit('hide');

    await nextTick();

    expect(findModal().props('visible')).toBe(false);
  });

  describe('tabs', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('displays All tab with count', () => {
      expect(trimText(findAllTab().text())).toBe(`All ${mockPipelineScheduleNodes.length}`);
    });

    it('displays Active tab with no count', () => {
      expect(findActiveTab().text()).toBe('Active');
    });

    it('displays Inactive tab with no count', () => {
      expect(findInactiveTab().text()).toBe('Inactive');
    });
  });

  it('should refetch the schedules query on a tab click', async () => {
    createComponent();

    await waitForPromises();

    jest.spyOn(wrapper.vm.$apollo.queries.schedules, 'refetch').mockImplementation(jest.fn());

    expect(wrapper.vm.$apollo.queries.schedules.refetch).toHaveBeenCalledTimes(0);

    await findAllTab().trigger('click');

    expect(wrapper.vm.$apollo.queries.schedules.refetch).toHaveBeenCalledTimes(1);
  });
});
