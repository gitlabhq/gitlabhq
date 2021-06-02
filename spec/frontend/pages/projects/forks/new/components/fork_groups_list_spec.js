import { GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import ForkGroupsList from '~/pages/projects/forks/new/components/fork_groups_list.vue';
import ForkGroupsListItem from '~/pages/projects/forks/new/components/fork_groups_list_item.vue';

jest.mock('~/flash');

describe('Fork groups list component', () => {
  let wrapper;
  let axiosMock;

  const DEFAULT_PROPS = {
    endpoint: '/dummy',
  };

  const replyWith = (...args) => axiosMock.onGet(DEFAULT_PROPS.endpoint).reply(...args);

  const createWrapper = (propsData) => {
    wrapper = shallowMount(ForkGroupsList, {
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      stubs: {
        GlTabs: {
          template: '<div><slot></slot><slot name="tabs-end"></slot></div>',
        },
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();

    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('fires load groups request on mount', async () => {
    replyWith(200, { namespaces: [] });
    createWrapper();

    await waitForPromises();

    expect(axiosMock.history.get[0].url).toBe(DEFAULT_PROPS.endpoint);
  });

  it('displays flash if loading groups fails', async () => {
    replyWith(500);
    createWrapper();

    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });

  it('displays loading indicator while loading groups', () => {
    replyWith(() => new Promise(() => {}));
    createWrapper();

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays empty text if no groups are available', async () => {
    const EMPTY_TEXT = 'No available groups to fork the project.';
    replyWith(200, { namespaces: [] });
    createWrapper();

    await waitForPromises();

    expect(wrapper.text()).toContain(EMPTY_TEXT);
  });

  it('displays filter field when groups are available', async () => {
    replyWith(200, { namespaces: [{ name: 'dummy1' }, { name: 'dummy2' }] });
    createWrapper();

    await waitForPromises();

    expect(wrapper.find(GlSearchBoxByType).exists()).toBe(true);
  });

  it('renders list items for each available group', async () => {
    const namespaces = [{ name: 'dummy1' }, { name: 'dummy2' }, { name: 'otherdummy' }];

    replyWith(200, { namespaces });
    createWrapper();

    await waitForPromises();

    expect(wrapper.findAll(ForkGroupsListItem)).toHaveLength(namespaces.length);

    namespaces.forEach((namespace, idx) => {
      expect(wrapper.findAll(ForkGroupsListItem).at(idx).props()).toStrictEqual({
        group: namespace,
      });
    });
  });

  it('filters repositories on the fly', async () => {
    replyWith(200, {
      namespaces: [{ name: 'dummy1' }, { name: 'dummy2' }, { name: 'otherdummy' }],
    });
    createWrapper();
    await waitForPromises();
    wrapper.find(GlSearchBoxByType).vm.$emit('input', 'other');
    await nextTick();

    expect(wrapper.findAll(ForkGroupsListItem)).toHaveLength(1);
    expect(wrapper.findAll(ForkGroupsListItem).at(0).props().group.name).toBe('otherdummy');
  });
});
