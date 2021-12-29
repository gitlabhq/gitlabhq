import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobControls from '~/repository/components/blob_controls.vue';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createRouter from '~/repository/router';
import { blobControlsDataMock, refMock } from '../mock_data';

let router;
let wrapper;
let mockResolver;

const localVue = createLocalVue();

const createComponent = async () => {
  localVue.use(VueApollo);

  const project = { ...blobControlsDataMock };
  const projectPath = 'some/project';

  router = createRouter(projectPath, refMock);

  router.replace({ name: 'blobPath', params: { path: '/some/file.js' } });

  mockResolver = jest.fn().mockResolvedValue({ data: { project } });

  wrapper = shallowMountExtended(BlobControls, {
    localVue,
    router,
    apolloProvider: createMockApollo([[blobControlsQuery, mockResolver]]),
    propsData: { projectPath },
    mixins: [{ data: () => ({ ref: refMock }) }],
  });

  await waitForPromises();
};

describe('Blob controls component', () => {
  const findFindButton = () => wrapper.findByTestId('find');
  const findBlameButton = () => wrapper.findByTestId('blame');
  const findHistoryButton = () => wrapper.findByTestId('history');
  const findPermalinkButton = () => wrapper.findByTestId('permalink');

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  it('renders a find button with the correct href', () => {
    expect(findFindButton().attributes('href')).toBe('find/file.js');
  });

  it('renders a blame button with the correct href', () => {
    expect(findBlameButton().attributes('href')).toBe('blame/file.js');
  });

  it('renders a history button with the correct href', () => {
    expect(findHistoryButton().attributes('href')).toBe('history/file.js');
  });

  it('renders a permalink button with the correct href', () => {
    expect(findPermalinkButton().attributes('href')).toBe('permalink/file.js');
  });

  it('does not render any buttons if no filePath is provided', async () => {
    router.replace({ name: 'blobPath', params: { path: null } });

    await nextTick();

    expect(findFindButton().exists()).toBe(false);
    expect(findBlameButton().exists()).toBe(false);
    expect(findHistoryButton().exists()).toBe(false);
    expect(findPermalinkButton().exists()).toBe(false);
  });
});
