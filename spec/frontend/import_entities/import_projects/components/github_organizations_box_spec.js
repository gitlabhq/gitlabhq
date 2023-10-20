import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { captureException } from '~/sentry/sentry_browser_wrapper';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';

import GithubOrganizationsBox from '~/import_entities/import_projects/components/github_organizations_box.vue';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/alert');

const MOCK_RESPONSE = {
  provider_groups: [{ name: 'alpha-1' }, { name: 'alpha-2' }, { name: 'beta-1' }],
};

describe('GithubOrganizationsBox component', () => {
  let wrapper;
  let mockAxios;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const mockGithubGroupPath = '/mock/groups.json';

  const createComponent = (props) => {
    wrapper = mount(GithubOrganizationsBox, {
      propsData: {
        value: 'some-org',
        ...props,
      },
      provide: () => ({
        statusImportGithubGroupPath: mockGithubGroupPath,
      }),
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(mockGithubGroupPath).reply(HTTP_STATUS_OK, MOCK_RESPONSE);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('has underlying listbox as loading while loading organizations', () => {
    createComponent();
    expect(findListbox().props('loading')).toBe(true);
  });

  it('clears underlying listbox when loading is complete', async () => {
    createComponent();
    await axios.waitForAll();
    expect(findListbox().props('loading')).toBe(false);
  });

  it('sets toggle-text to all organizations when selection is not provided', () => {
    createComponent({ value: '' });
    expect(findListbox().props('toggleText')).toBe(GithubOrganizationsBox.i18n.allOrganizations);
  });

  it('sets toggle-text to organization name when it is provided', () => {
    const ORG_NAME = 'org';
    createComponent({ value: ORG_NAME });

    expect(findListbox().props('toggleText')).toBe(ORG_NAME);
  });

  it('emits selected organization from underlying listbox', () => {
    createComponent();

    findListbox().vm.$emit('select', 'org-id');
    expect(wrapper.emitted('input').at(-1)).toStrictEqual(['org-id']);
  });

  it('filters list for underlying listbox', async () => {
    createComponent();
    await axios.waitForAll();

    findListbox().vm.$emit('search', 'alpha');
    await nextTick();

    // 2 matches + 'All organizations'
    expect(findListbox().props('items')).toHaveLength(3);
  });

  it('reports error to sentry on load', async () => {
    mockAxios.onGet(mockGithubGroupPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    await axios.waitForAll();

    expect(captureException).toHaveBeenCalled();
    expect(createAlert).toHaveBeenCalled();
  });
});
