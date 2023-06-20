import { GlButton, GlListboxItem, GlCollapsibleListbox } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import searchQuery from '~/pages/projects/forks/new/queries/search_forkable_namespaces.query.graphql';
import ProjectNamespace from '~/pages/projects/forks/new/components/project_namespace.vue';

jest.mock('~/alert');

describe('ProjectNamespace component', () => {
  let wrapper;

  const data = {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      forkTargets: {
        nodes: [
          {
            id: 'gid://gitlab/Group/21',
            fullPath: 'flightjs',
            name: 'Flight JS',
            visibility: 'public',
          },
          {
            id: 'gid://gitlab/Namespace/4',
            fullPath: 'root',
            name: 'Administrator',
            visibility: 'public',
          },
        ],
      },
    },
  };

  const mockQueryResponse = jest.fn().mockResolvedValue({ data });

  const emptyQueryResponse = {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      forkTargets: {
        nodes: [],
      },
    },
  };

  const mockQueryError = jest.fn().mockRejectedValue(new Error('Network error'));

  Vue.use(VueApollo);

  const gitlabUrl = 'https://gitlab.com';

  const defaultProvide = {
    projectFullPath: 'gitlab-org/project',
  };

  const mountComponent = ({
    provide = defaultProvide,
    queryHandler = mockQueryResponse,
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [[searchQuery, queryHandler]];
    const apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(ProjectNamespace, {
      apolloProvider,
      provide,
    });
  };

  const findButtonLabel = () => wrapper.findComponent(GlButton);
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListBoxText = () => findListBox().props('toggleText');

  const clickListBoxItem = async (value = '') => {
    wrapper.findComponent(GlListboxItem).vm.$emit('select', value);
    await nextTick();
  };

  const showDropdown = () => {
    findListBox().vm.$emit('shown');
  };

  beforeEach(() => {
    gon.gitlab_url = gitlabUrl;
  });

  describe('Initial state', () => {
    beforeEach(() => {
      mountComponent({ mountFn: mount });
      jest.runOnlyPendingTimers();
    });

    it('renders the root url as a label', () => {
      expect(findButtonLabel().text()).toBe(`${gitlabUrl}/`);
      expect(findButtonLabel().props('label')).toBe(true);
    });

    it('renders placeholder text', () => {
      expect(findListBoxText()).toBe('Select a namespace');
    });
  });

  describe('After user interactions', () => {
    beforeEach(async () => {
      mountComponent({ mountFn: mount });
      jest.runOnlyPendingTimers();
      await nextTick();
      showDropdown();
    });

    it('displays fetched namespaces', () => {
      const listItems = wrapper.findAll('[role="option"]');
      expect(listItems).toHaveLength(2);
      expect(listItems.at(0).text()).toBe(data.project.forkTargets.nodes[0].fullPath);
      expect(listItems.at(1).text()).toBe(data.project.forkTargets.nodes[1].fullPath);
    });

    it('sets the selected namespace', async () => {
      const { fullPath } = data.project.forkTargets.nodes[0];
      await clickListBoxItem(fullPath);

      expect(findListBoxText()).toBe(fullPath);
    });
  });

  describe('With empty query response', () => {
    beforeEach(() => {
      mountComponent({ queryHandler: emptyQueryResponse, mountFn: mount });
      jest.runOnlyPendingTimers();
    });

    it('renders `No matches found`', () => {
      expect(findListBox().text()).toContain('No matches found');
    });
  });

  describe('With error while fetching data', () => {
    beforeEach(async () => {
      mountComponent({ queryHandler: mockQueryError });
      jest.runOnlyPendingTimers();
      await nextTick();
    });

    it('creates an alert and captures the error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while loading data. Please refresh the page to try again.',
        captureError: true,
        error: expect.any(Error),
      });
    });
  });
});
