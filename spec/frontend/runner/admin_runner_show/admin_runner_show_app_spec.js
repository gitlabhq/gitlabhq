import Vue from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/runner/components/runner_header.vue';
import RunnerDetails from '~/runner/components/runner_details.vue';
import RunnerPauseButton from '~/runner/components/runner_pause_button.vue';
import RunnerEditButton from '~/runner/components/runner_edit_button.vue';
import getRunnerQuery from '~/runner/graphql/get_runner.query.graphql';
import AdminRunnerShowApp from '~/runner/admin_runner_show/admin_runner_show_app.vue';
import { captureException } from '~/runner/sentry_utils';

import { runnerData } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerGraphqlId = mockRunner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;

Vue.use(VueApollo);

describe('AdminRunnerShowApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);
  const findRunnerEditButton = () => wrapper.findComponent(RunnerEditButton);
  const findRunnerPauseButton = () => wrapper.findComponent(RunnerPauseButton);

  const mockRunnerQueryResult = (runner = {}) => {
    mockRunnerQuery = jest.fn().mockResolvedValue({
      data: {
        runner: { ...mockRunner, ...runner },
      },
    });
  };

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

  afterEach(() => {
    mockRunnerQuery.mockReset();
    wrapper.destroy();
  });

  describe('When showing runner details', () => {
    beforeEach(async () => {
      mockRunnerQueryResult();

      await createComponent({ mountFn: mount });
    });

    it('expect GraphQL ID to be requested', async () => {
      expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
    });

    it('displays the runner header', async () => {
      expect(findRunnerHeader().text()).toContain(`Runner #${mockRunnerId}`);
    });

    it('displays the runner edit and pause buttons', async () => {
      expect(findRunnerEditButton().exists()).toBe(true);
      expect(findRunnerPauseButton().exists()).toBe(true);
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

    describe('when runner cannot be updated', () => {
      beforeEach(async () => {
        mockRunnerQueryResult({
          userPermissions: {
            updateRunner: false,
          },
        });

        await createComponent({
          mountFn: mount,
        });
      });

      it('does not display the runner edit and pause buttons', () => {
        expect(findRunnerEditButton().exists()).toBe(false);
        expect(findRunnerPauseButton().exists()).toBe(false);
      });
    });

    describe('when runner does not have an edit url ', () => {
      beforeEach(async () => {
        mockRunnerQueryResult({
          editAdminUrl: null,
        });

        await createComponent({
          mountFn: mount,
        });
      });

      it('does not display the runner edit button', () => {
        expect(findRunnerEditButton().exists()).toBe(false);
        expect(findRunnerPauseButton().exists()).toBe(true);
      });
    });
  });

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponent();
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'AdminRunnerShowApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
