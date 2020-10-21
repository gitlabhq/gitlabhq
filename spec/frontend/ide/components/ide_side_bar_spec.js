import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlSkeletonLoading } from '@gitlab/ui';
import { createStore } from '~/ide/stores';
import IdeSidebar from '~/ide/components/ide_side_bar.vue';
import IdeTree from '~/ide/components/ide_tree.vue';
import RepoCommitSection from '~/ide/components/repo_commit_section.vue';
import { leftSidebarViews } from '~/ide/constants';
import { projectData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IdeSidebar', () => {
  let wrapper;
  let store;

  function createComponent() {
    store = createStore();

    store.state.currentProjectId = 'abcproject';
    store.state.projects.abcproject = projectData;

    return mount(IdeSidebar, {
      store,
      localVue,
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders a sidebar', () => {
    wrapper = createComponent();

    expect(wrapper.find('[data-testid="ide-side-bar-inner"]').exists()).toBe(true);
  });

  it('renders loading components', async () => {
    wrapper = createComponent();

    store.state.loading = true;

    await wrapper.vm.$nextTick();

    expect(wrapper.findAll(GlSkeletonLoading)).toHaveLength(3);
  });

  describe('activityBarComponent', () => {
    it('renders tree component', () => {
      wrapper = createComponent();

      expect(wrapper.find(IdeTree).exists()).toBe(true);
    });

    it('renders commit component', async () => {
      wrapper = createComponent();

      store.state.currentActivityView = leftSidebarViews.commit.name;

      await wrapper.vm.$nextTick();

      expect(wrapper.find(RepoCommitSection).exists()).toBe(true);
    });
  });

  it('keeps the current activity view components alive', async () => {
    wrapper = createComponent();

    const ideTreeComponent = wrapper.find(IdeTree).element;

    store.state.currentActivityView = leftSidebarViews.commit.name;

    await wrapper.vm.$nextTick();

    expect(wrapper.find(IdeTree).exists()).toBe(false);
    expect(wrapper.find(RepoCommitSection).exists()).toBe(true);

    store.state.currentActivityView = leftSidebarViews.edit.name;

    await wrapper.vm.$nextTick();

    // reference to the elements remains the same, meaning the components were kept alive
    expect(wrapper.find(IdeTree).element).toEqual(ideTreeComponent);
  });
});
