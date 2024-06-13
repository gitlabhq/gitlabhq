import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import PipelinesTableWrapper from '~/ci/merge_requests/components/pipelines_table_wrapper.vue';
import { MR_PIPELINE_TYPE_DETACHED } from '~/ci/merge_requests/constants';
import getMergeRequestsPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';

import { generateMRPipelinesResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

let wrapper;
let mergeRequestPipelinesRequest;
let apolloMock;

const defaultProvide = {
  graphqlPath: '/api/graphql/',
  mergeRequestId: 1,
  targetProjectFullPath: '/group/project',
};

const defaultProps = {
  canRunPipeline: true,
  projectId: '5',
  mergeRequestId: 3,
  errorStateSvgPath: 'error-svg',
  emptyStateSvgPath: 'empty-svg',
};

const createComponent = ({ mountFn = shallowMountExtended, props = {} } = {}) => {
  const handlers = [[getMergeRequestsPipelines, mergeRequestPipelinesRequest]];

  apolloMock = createMockApollo(handlers);

  wrapper = mountFn(PipelinesTableWrapper, {
    apolloProvider: apolloMock,
    provide: {
      ...defaultProvide,
    },
    propsData: {
      ...defaultProps,
      ...props,
    },
  });

  return waitForPromises();
};

const findEmptyState = () => wrapper.findByTestId('pipeline-empty-state');
const findErrorEmptyState = () => wrapper.findByTestId('pipeline-error-empty-state');
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findMrPipelinesDocsLink = () => wrapper.findByTestId('mr-pipelines-docs-link');
const findPipelinesList = () => wrapper.findComponent(PipelinesTable);
const findRunPipelineBtn = () => wrapper.findByTestId('run_pipeline_button');
const findRunPipelineBtnMobile = () => wrapper.findByTestId('run_pipeline_button_mobile');
const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
const findUserPermissionsDocsLink = () => wrapper.findByTestId('user-permissions-docs-link');

beforeEach(() => {
  mergeRequestPipelinesRequest = jest.fn();
  mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 1 }));
});

afterEach(() => {
  apolloMock = null;
});

describe('PipelinesTableWrapper component', () => {
  describe('When queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render the pipeline list', () => {
      expect(findPipelinesList().exists()).toBe(false);
    });
  });

  describe('When there is an error fetching pipelines', () => {
    beforeEach(async () => {
      mergeRequestPipelinesRequest.mockRejectedValueOnce({ error: 'API error message' });
      await createComponent({ mountFn: mountExtended });
    });

    it('should render error state', () => {
      expect(findErrorEmptyState().text()).toBe(
        'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
      );
    });
  });

  describe('When queries have loaded', () => {
    it('does not render the loading icon', async () => {
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    describe('with pipelines', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('renders a pipeline list', () => {
        expect(findPipelinesList().exists()).toBe(true);
        expect(findPipelinesList().props().pipelines).toHaveLength(1);
      });
    });

    describe('without pipelines', () => {
      beforeEach(async () => {
        mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 0 }));
        await createComponent({ mountFn: mountExtended });
      });

      it('should render the empty state', () => {
        expect(findTableRows()).toHaveLength(0);
        expect(findErrorEmptyState().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should render correct empty state content', () => {
        expect(findRunPipelineBtn().exists()).toBe(true);
        expect(findMrPipelinesDocsLink().attributes('href')).toBe(
          '/help/ci/pipelines/merge_request_pipelines.md#prerequisites',
        );
        expect(findUserPermissionsDocsLink().attributes('href')).toBe(
          '/help/user/permissions.md#gitlab-cicd-permissions',
        );

        expect(findEmptyState().text()).toContain('To run a merge request pipeline');
      });
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('polls every 10 seconds', async () => {
      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);
      await waitForPromises();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);
      await waitForPromises();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(2);
    });
  });

  describe('run pipeline button', () => {
    describe('when latest pipeline has detached flag', () => {
      beforeEach(async () => {
        const response = generateMRPipelinesResponse({
          mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED,
        });

        mergeRequestPipelinesRequest.mockResolvedValue(response);

        createComponent({ mountFn: mountExtended });

        await waitForPromises();
      });

      it('renders the run pipeline button', () => {
        expect(findRunPipelineBtn().exists()).toBe(true);
        expect(findRunPipelineBtnMobile().exists()).toBe(true);
      });
    });
  });
});
