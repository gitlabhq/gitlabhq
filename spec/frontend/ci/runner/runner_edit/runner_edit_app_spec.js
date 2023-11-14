import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerUpdateForm from '~/ci/runner/components/runner_update_form.vue';
import runnerFormQuery from '~/ci/runner/graphql/edit/runner_form.query.graphql';
import RunnerEditApp from '~/ci/runner/runner_edit/runner_edit_app.vue';
import { captureException } from '~/ci/runner/sentry_utils';
import { I18N_STATUS_NEVER_CONTACTED, I18N_INSTANCE_TYPE } from '~/ci/runner/constants';

import { runnerFormData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mockRunner = runnerFormData.data.runner;
const mockRunnerGraphqlId = mockRunner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;
const mockRunnerSha = mockRunner.shortSha;
const mockRunnerPath = `/admin/runners/${mockRunnerId}`;

Vue.use(VueApollo);

describe('RunnerEditApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerUpdateForm = () => wrapper.findComponent(RunnerUpdateForm);

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerEditApp, {
      apolloProvider: createMockApollo([[runnerFormQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        runnerPath: mockRunnerPath,
        ...props,
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnerQuery = jest.fn().mockResolvedValue(runnerFormData);
  });

  afterEach(() => {
    mockRunnerQuery.mockReset();
  });

  it('expect GraphQL ID to be requested', async () => {
    await createComponentWithApollo();

    expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
  });

  it('displays the runner id and creation date', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerHeader().text()).toContain(`#${mockRunnerId} (${mockRunnerSha})`);
    expect(findRunnerHeader().text()).toContain('Created');
  });

  it('displays the runner type and status', async () => {
    await createComponentWithApollo({ mountFn: mount });

    expect(findRunnerHeader().text()).toContain(I18N_STATUS_NEVER_CONTACTED);
    expect(findRunnerHeader().text()).toContain(I18N_INSTANCE_TYPE);
  });

  it('displays a loading runner form', () => {
    createComponentWithApollo();

    expect(findRunnerUpdateForm().props()).toMatchObject({
      runner: null,
      loading: true,
      runnerPath: mockRunnerPath,
    });
  });

  it('displays the runner form', async () => {
    await createComponentWithApollo();

    expect(findRunnerUpdateForm().props()).toMatchObject({
      loading: false,
      runnerPath: mockRunnerPath,
    });
    expect(findRunnerUpdateForm().props('runner')).toEqual(mockRunner);
  });

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponentWithApollo();
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'RunnerEditApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
