import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineSchedules from '~/pipeline_schedules/components/pipeline_schedules.vue';
import PipelineSchedulesTable from '~/pipeline_schedules/components/table/pipeline_schedules_table.vue';
import getPipelineSchedulesQuery from '~/pipeline_schedules/graphql/queries/get_pipeline_schedules.query.graphql';
import { mockGetPipelineSchedulesGraphQLResponse, mockPipelineScheduleNodes } from '../mock_data';

Vue.use(VueApollo);

describe('Pipeline schedules app', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockGetPipelineSchedulesGraphQLResponse);

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getPipelineSchedulesQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (handler = successHandler) => {
    wrapper = shallowMount(PipelineSchedules, {
      provide: {
        fullPath: 'gitlab-org/gitlab',
      },
      apolloProvider: createMockApolloProvider(handler),
    });
  };

  const findTable = () => wrapper.findComponent(PipelineSchedulesTable);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('fetches query and passes an array of pipeline schedules', async () => {
    expect(successHandler).toHaveBeenCalled();

    await waitForPromises();

    expect(findTable().props('schedules')).toEqual(mockPipelineScheduleNodes);
  });
});
