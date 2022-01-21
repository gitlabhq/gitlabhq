import Vue from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/runner/components/runner_header.vue';
import RunnerDetails from '~/runner/components/runner_details.vue';
import getRunnerQuery from '~/runner/graphql/get_runner.query.graphql';
import AdminRunnerShowApp from '~/runner/admin_runner_show/admin_runner_show_app.vue';
import { captureException } from '~/runner/sentry_utils';

import { runnerData } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const mockRunnerGraphqlId = runnerData.data.runner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;

Vue.use(VueApollo);

describe('AdminRunnerShowApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);

  const createComponent = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(AdminRunnerShowApp, {
      apolloProvider: createMockApollo([[getRunnerQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        ...props,
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnerQuery = jest.fn().mockResolvedValue(runnerData);
  });

  afterEach(() => {
    mockRunnerQuery.mockReset();
    wrapper.destroy();
  });

  describe('When showing runner details', () => {
    beforeEach(async () => {
      await createComponent({ mountFn: mount });
    });

    it('expect GraphQL ID to be requested', async () => {
      expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
    });

    it('displays the runner header', async () => {
      expect(findRunnerHeader().text()).toContain(`Runner #${mockRunnerId}`);
    });

    it('shows basic runner details', async () => {
      const expected = `Details
                        Description Instance runner
                        Last contact Never contacted
                        Version 1.0.0
                        IP Address 127.0.0.1
                        Configuration Runs untagged jobs
                        Maximum job timeout None
                        Tags None`.replace(/\s+/g, ' ');

      expect(findRunnerDetails().text()).toMatchInterpolatedText(expected);
    });
  });

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponent();
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Network error: Error!'),
        component: 'AdminRunnerShowApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
