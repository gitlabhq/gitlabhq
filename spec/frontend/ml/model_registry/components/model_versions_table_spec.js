import { GlTable, GlLink, GlAvatarLink, GlAvatar, GlDisclosureDropdown } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ModelVersionsTable from '~/ml/model_registry/components/model_versions_table.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import deleteModelVersionMutation from '~/ml/model_registry/graphql/mutations/delete_model_version.mutation.graphql';
import ModelVersionActionsDropdown from '~/ml/model_registry/components/model_version_actions_dropdown.vue';
import { createAlert } from '~/alert';
import {
  modelVersionWithCandidateAndAuthor,
  modelVersionWithCandidateAndNullAuthor,
  deleteModelVersionResponses,
} from '../graphql_mock_data';

jest.mock('~/alert');

let wrapper;
let apolloProvider;
describe('ModelVersionsTable', () => {
  Vue.use(VueApollo);

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const items = [modelVersionWithCandidateAndAuthor];

  const createWrapper = ({
    deleteResolver = jest.fn().mockResolvedValue(deleteModelVersionResponses.success),
    canWriteModelRegistry = true,
    mountFn = mountExtended,
    tableItems = items,
  } = {}) => {
    const requestHandlers = [[deleteModelVersionMutation, deleteResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(ModelVersionsTable, {
      provide: {
        canWriteModelRegistry,
      },
      propsData: {
        items: tableItems,
        canWriteModelRegistry,
      },
      apolloProvider,
      stubs: {
        ModelVersionActionsDropdown,
      },
    });

    return waitForPromises();
  };

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findGlTable().findAll('tbody tr');
  const findActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  beforeEach(() => {
    createWrapper();
  });

  it('renders the table', () => {
    expect(findGlTable().exists()).toBe(true);
  });

  it('has the correct columns in the table', () => {
    expect(findGlTable().props('fields')).toEqual([
      { key: 'version', label: 'Version', thClass: 'gl-w-1/3' },
      { key: 'createdAt', label: 'Created', thClass: 'gl-w-1/3' },
      { key: 'author', label: 'Created by' },
      {
        key: 'actions',
        label: '',
        tdClass: 'lg:gl-w-px gl-whitespace-nowrap !gl-p-3 gl-text-right',
        thClass: 'lg:gl-w-px gl-whitespace-nowrap',
      },
    ]);
  });

  it('renders the correct number of rows', () => {
    expect(findTableRows()).toHaveLength(1);
  });

  it('renders the version link correctly', () => {
    const versionLink = findTableRows().at(0).findComponent(GlLink);
    expect(versionLink.attributes('href')).toBe(items[0]._links.showPath);
    expect(versionLink.text()).toBe(items[0].version);
  });

  it('renders the createdAt tooltip correctly', () => {
    const timeAgoTooltip = findTableRows().at(0).findComponent(TimeAgoTooltip);
    expect(timeAgoTooltip.props('time')).toBe(items[0].createdAt);
  });

  it('renders the author information correctly', () => {
    const avatarLink = findTableRows().at(0).findComponent(GlAvatarLink);
    expect(avatarLink.attributes('href')).toBe(items[0].author.webUrl);
    expect(avatarLink.attributes('title')).toBe(items[0].author.name);

    const avatar = avatarLink.findComponent(GlAvatar);
    expect(avatar.props('src')).toBe(items[0].author.avatarUrl);
    expect(avatarLink.text()).toContain(items[0].author.name);
  });

  it('renders the author information correctly for items with no author', () => {
    createWrapper({ tableItems: [modelVersionWithCandidateAndNullAuthor] });
    const avatarLink = findTableRows().at(0).findComponent(GlAvatarLink);
    expect(avatarLink.exists()).toBe(false);
  });

  it('renders actions dropdown if canWriteModelRegistry is true', () => {
    createWrapper({}, true);
    expect(findActionsDropdown().exists()).toBe(true);
  });

  it('does not render actions if canWriteModelRegistry is false', () => {
    createWrapper({ canWriteModelRegistry: false });
    expect(findActionsDropdown().exists()).toBe(false);
  });

  it('emits model-versions-update upon successful delete mutation', async () => {
    createWrapper();
    jest.spyOn(apolloProvider.defaultClient, 'mutate');

    wrapper.findComponent(ModelVersionActionsDropdown).vm.$emit('delete-model-version', 2);

    await waitForPromises();

    expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
      expect.objectContaining({
        mutation: deleteModelVersionMutation,
        variables: {
          id: 'gid://gitlab/Ml::ModelVersion/2',
        },
      }),
    );
    expect(wrapper.emitted('model-versions-update')).toHaveLength(1);
  });

  it('Logs to sentry upon failed delete mutation', async () => {
    createWrapper({
      deleteResolver: jest.fn().mockResolvedValue(deleteModelVersionResponses.failure),
    });

    wrapper.findComponent(ModelVersionActionsDropdown).vm.$emit('delete-model-version', 2);

    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalledWith(
      'Model version not found, Project not found',
      {
        tags: { vue_component: 'model_versions_table' },
      },
    );

    expect(wrapper.emitted('model-versions-update')).toBeUndefined();

    expect(createAlert).toHaveBeenCalledWith({
      message:
        'Something went wrong while trying to delete the model version. Please try again later.',
      variant: 'danger',
    });
  });
});
