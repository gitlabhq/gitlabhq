import {
  GlIcon,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownForm,
  GlDropdownItem,
  GlSearchBoxByType,
  GlButton,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import IssuableMoveDropdown from '~/vue_shared/components/sidebar/issuable_move_dropdown.vue';

const mockProjects = [
  {
    id: 2,
    name_with_namespace: 'Gitlab Org / Gitlab Shell',
    full_path: 'gitlab-org/gitlab-shell',
  },
  {
    id: 3,
    name_with_namespace: 'Gnuwget / Wget2',
    full_path: 'gnuwget/wget2',
  },
  {
    id: 4,
    name_with_namespace: 'Commit451 / Lab Coat',
    full_path: 'Commit451/lab-coat',
  },
];

const mockProps = {
  projectsFetchPath: '/-/autocomplete/projects?project_id=1',
  dropdownButtonTitle: 'Move issuable',
  dropdownHeaderTitle: 'Move issuable',
  moveInProgress: false,
};

const mockEvent = {
  stopPropagation: jest.fn(),
  preventDefault: jest.fn(),
};

const createComponent = (propsData = mockProps) =>
  shallowMount(IssuableMoveDropdown, {
    propsData,
  });

describe('IssuableMoveDropdown', () => {
  let mock;
  let wrapper;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createComponent();
    wrapper.vm.$refs.dropdown.hide = jest.fn();
    wrapper.vm.$refs.searchInput.focusInput = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('watch', () => {
    describe('searchKey', () => {
      it('calls `fetchProjects` with value of the prop', async () => {
        jest.spyOn(wrapper.vm, 'fetchProjects');
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          searchKey: 'foo',
        });

        await nextTick();

        expect(wrapper.vm.fetchProjects).toHaveBeenCalledWith('foo');
      });
    });
  });

  describe('methods', () => {
    describe('fetchProjects', () => {
      it('sets projectsListLoading to true and projectsListLoadFailed to false', () => {
        wrapper.vm.fetchProjects();

        expect(wrapper.vm.projectsListLoading).toBe(true);
        expect(wrapper.vm.projectsListLoadFailed).toBe(false);
      });

      it('calls `axios.get` with `projectsFetchPath` and query param `search`', () => {
        jest.spyOn(axios, 'get').mockResolvedValue({
          data: mockProjects,
        });

        wrapper.vm.fetchProjects('foo');

        expect(axios.get).toHaveBeenCalledWith(
          mockProps.projectsFetchPath,
          expect.objectContaining({
            params: {
              search: 'foo',
            },
          }),
        );
      });

      it('sets response to `projects` and focuses on searchInput when request is successful', async () => {
        jest.spyOn(axios, 'get').mockResolvedValue({
          data: mockProjects,
        });

        await wrapper.vm.fetchProjects('foo');

        expect(wrapper.vm.projects).toBe(mockProjects);
        expect(wrapper.vm.$refs.searchInput.focusInput).toHaveBeenCalled();
      });

      it('sets projectsListLoadFailed to true when request fails', async () => {
        jest.spyOn(axios, 'get').mockRejectedValue({});

        await wrapper.vm.fetchProjects('foo');

        expect(wrapper.vm.projectsListLoadFailed).toBe(true);
      });

      it('sets projectsListLoading to false when request completes', async () => {
        jest.spyOn(axios, 'get').mockResolvedValue({
          data: mockProjects,
        });

        await wrapper.vm.fetchProjects('foo');

        expect(wrapper.vm.projectsListLoading).toBe(false);
      });
    });

    describe('isSelectedProject', () => {
      it.each`
        project            | selectedProject    | title                       | returnValue
        ${mockProjects[0]} | ${mockProjects[0]} | ${'are same projects'}      | ${true}
        ${mockProjects[0]} | ${mockProjects[1]} | ${'are different projects'} | ${false}
      `(
        'returns $returnValue when selectedProject and provided project param $title',
        async ({ project, selectedProject, returnValue }) => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            selectedProject,
          });

          await nextTick();

          expect(wrapper.vm.isSelectedProject(project)).toBe(returnValue);
        },
      );

      it('returns false when selectedProject is null', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          selectedProject: null,
        });

        await nextTick();

        expect(wrapper.vm.isSelectedProject(mockProjects[0])).toBe(false);
      });
    });
  });

  describe('template', () => {
    const findDropdownEl = () => wrapper.findComponent(GlDropdown);

    it('renders collapsed state element with icon', () => {
      const collapsedEl = wrapper.find('[data-testid="move-collapsed"]');

      expect(collapsedEl.exists()).toBe(true);
      expect(collapsedEl.attributes('title')).toBe(mockProps.dropdownButtonTitle);
      expect(collapsedEl.findComponent(GlIcon).exists()).toBe(true);
      expect(collapsedEl.findComponent(GlIcon).props('name')).toBe('arrow-right');
    });

    describe('gl-dropdown component', () => {
      it('renders component container element', () => {
        expect(findDropdownEl().exists()).toBe(true);
        expect(findDropdownEl().props('block')).toBe(true);
      });

      it('renders gl-dropdown-form component', () => {
        expect(findDropdownEl().findComponent(GlDropdownForm).exists()).toBe(true);
      });

      it('renders header element', () => {
        const headerEl = findDropdownEl().find('[data-testid="header"]');

        expect(headerEl.exists()).toBe(true);
        expect(headerEl.find('span').text()).toBe(mockProps.dropdownHeaderTitle);
        expect(headerEl.findComponent(GlButton).props('icon')).toBe('close');
      });

      it('renders gl-search-box-by-type component', () => {
        const searchEl = findDropdownEl().findComponent(GlSearchBoxByType);

        expect(searchEl.exists()).toBe(true);
        expect(searchEl.attributes()).toMatchObject({
          placeholder: 'Search project',
          debounce: '300',
        });
      });

      it('renders gl-loading-icon component when projectsListLoading prop is true', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          projectsListLoading: true,
        });

        await nextTick();

        expect(findDropdownEl().findComponent(GlLoadingIcon).exists()).toBe(true);
      });

      it('renders gl-dropdown-item components for available projects', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          projects: mockProjects,
          selectedProject: mockProjects[0],
        });

        await nextTick();

        const dropdownItems = wrapper.findAllComponents(GlDropdownItem);

        expect(dropdownItems).toHaveLength(mockProjects.length);
        expect(dropdownItems.at(0).props()).toMatchObject({
          isCheckItem: true,
          isChecked: true,
        });
        expect(dropdownItems.at(0).text()).toBe(mockProjects[0].name_with_namespace);
      });

      it('renders string "No matching results" when search does not yield any matches', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          searchKey: 'foo',
        });

        // Wait for `searchKey` watcher to run.
        await nextTick();

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          projects: [],
          projectsListLoading: false,
        });

        await nextTick();

        const dropdownContentEl = wrapper.find('[data-testid="content"]');

        expect(dropdownContentEl.text()).toContain('No matching results');
      });

      it('renders string "Failed to load projects" when loading projects list fails', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          projects: [],
          projectsListLoading: false,
          projectsListLoadFailed: true,
        });

        await nextTick();

        const dropdownContentEl = wrapper.find('[data-testid="content"]');

        expect(dropdownContentEl.text()).toContain('Failed to load projects');
      });

      it('renders gl-button within footer', async () => {
        const moveButtonEl = wrapper.find('[data-testid="footer"]').findComponent(GlButton);

        expect(moveButtonEl.text()).toBe('Move');
        expect(moveButtonEl.attributes('disabled')).toBe('true');

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          selectedProject: mockProjects[0],
        });

        await nextTick();

        expect(
          wrapper.find('[data-testid="footer"]').findComponent(GlButton).attributes('disabled'),
        ).not.toBeDefined();
      });
    });

    describe('events', () => {
      it('collapsed state element emits `toggle-collapse` event on component when clicked', () => {
        wrapper.find('[data-testid="move-collapsed"]').trigger('click');

        expect(wrapper.emitted('toggle-collapse')).toBeTruthy();
      });

      it('gl-dropdown component calls `fetchProjects` on `shown` event', () => {
        jest.spyOn(axios, 'get').mockResolvedValue({
          data: mockProjects,
        });

        findDropdownEl().vm.$emit('shown');

        expect(axios.get).toHaveBeenCalled();
      });

      it('gl-dropdown component prevents dropdown body from closing on `hide` event when `projectItemClick` prop is true', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          projectItemClick: true,
        });

        findDropdownEl().vm.$emit('hide', mockEvent);

        expect(mockEvent.preventDefault).toHaveBeenCalled();
        expect(wrapper.vm.projectItemClick).toBe(false);
      });

      it('gl-dropdown component emits `dropdown-close` event on component from `hide` event', async () => {
        findDropdownEl().vm.$emit('hide');

        expect(wrapper.emitted('dropdown-close')).toBeTruthy();
      });

      it('close icon in dropdown header closes the dropdown when clicked', () => {
        wrapper.find('[data-testid="header"]').findComponent(GlButton).vm.$emit('click', mockEvent);

        expect(wrapper.vm.$refs.dropdown.hide).toHaveBeenCalled();
      });

      it('sets project for clicked gl-dropdown-item to selectedProject', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          projects: mockProjects,
        });

        await nextTick();

        wrapper.findAllComponents(GlDropdownItem).at(0).vm.$emit('click', mockEvent);

        expect(wrapper.vm.selectedProject).toBe(mockProjects[0]);
      });

      it('hides dropdown and emits `move-issuable` event when move button is clicked', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          selectedProject: mockProjects[0],
        });

        await nextTick();

        wrapper.find('[data-testid="footer"]').findComponent(GlButton).vm.$emit('click');

        expect(wrapper.vm.$refs.dropdown.hide).toHaveBeenCalled();
        expect(wrapper.emitted('move-issuable')).toBeTruthy();
        expect(wrapper.emitted('move-issuable')[0]).toEqual([mockProjects[0]]);
      });
    });
  });
});
