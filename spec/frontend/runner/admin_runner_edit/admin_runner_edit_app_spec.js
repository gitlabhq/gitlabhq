import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/runner/components/runner_header.vue';
import RunnerUpdateForm from '~/runner/components/runner_update_form.vue';
import runnerQuery from '~/runner/graphql/details/runner.query.graphql';
import AdminRunnerEditApp from '~//runner/admin_runner_edit/admin_runner_edit_app.vue';
import { captureException } from '~/runner/sentry_utils';

import { runnerData } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerGraphqlId = mockRunner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;
const mockRunnerUrl = `/admin/runners/${mockRunnerId}`;

Vue.use(VueApollo);

describe('AdminRunnerEditApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerUpdateForm = () => wrapper.findComponent(RunnerUpdateForm);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(AdminRunnerEditApp, {
      apolloProvider: createMockApollo([[runnerQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        runnerUrl: mockRunnerUrl,
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

  it('expect GraphQL ID to be requested', async () => {
    await createComponentWithApollo();

    expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
  });

  it('displays the runner id and creation date', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerHeader().text()).toContain(`Runner #${mockRunnerId}`);
    expect(findRunnerHeader().text()).toContain('created');
  });

  it('displays the runner type and status', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerHeader().text()).toContain(`never contacted`);
    expect(findRunnerHeader().text()).toContain(`shared`);
  });

  it('displays a loading runner form', () => {
    createComponentWithApollo();

    expect(findRunnerUpdateForm().props()).toMatchObject({
      runner: null,
      loading: true,
      runnerUrl: mockRunnerUrl,
    });
  });

  it('displays the runner form', async () => {
    await createComponentWithApollo();

    expect(findRunnerUpdateForm().props()).toMatchObject({
      runner: mockRunner,
      loading: false,
      runnerUrl: mockRunnerUrl,
    });
  });

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponentWithApollo();
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'AdminRunnerEditApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
