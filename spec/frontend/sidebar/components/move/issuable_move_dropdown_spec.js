import { nextTick } from 'vue';
import {
  GlIcon,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownForm,
  GlDropdownItem,
  GlSearchBoxByType,
  GlButton,
} from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import IssuableMoveDropdown from '~/sidebar/components/move/issuable_move_dropdown.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

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
  disabled: false,
};

const mockEvent = {
  stopPropagation: jest.fn(),
  preventDefault: jest.fn(),
};

const focusInputMock = jest.fn();
const hideMock = jest.fn();

describe('IssuableMoveDropdown', () => {
  let mock;
  let wrapper;

  const createComponent = (propsData = mockProps) => {
    wrapper = shallowMountExtended(IssuableMoveDropdown, {
      propsData,
      stubs: {
        GlDropdown: stubComponent(GlDropdown, {
          methods: {
            hide: hideMock,
          },
        }),
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          methods: {
            focusInput: focusInputMock,
          },
        }),
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(mockProps.projectsFetchPath).reply(HTTP_STATUS_OK, mockProjects);

    createComponent();
  });

  afterEach(() => {
    mock.restore();
  });

  const findCollapsedEl = () => wrapper.findByTestId('move-collapsed');
  const findFooter = () => wrapper.findByTestId('footer');
  const findHeader = () => wrapper.findByTestId('header');
  const findFailedLoadResults = () => wrapper.findByTestId('failed-load-results');
  const findDropdownContent = () => wrapper.findByTestId('content');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdownEl = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  describe('watch', () => {
    describe('searchKey', () => {
      it('calls `fetchProjects` with value of the prop', async () => {
        jest.spyOn(axios, 'get');
        findSearchBox().vm.$emit('input', 'foo');

        await waitForPromises();

        expect(axios.get).toHaveBeenCalledWith('/-/autocomplete/projects?project_id=1', {
          params: { search: 'foo' },
        });
      });
    });
  });

  describe('methods', () => {
    describe('fetchProjects', () => {
      it('sets projectsListLoading to true and projectsListLoadFailed to false', async () => {
        findDropdownEl().vm.$emit('shown');
        await nextTick();

        expect(findLoadingIcon().exists()).toBe(true);
        expect(findFailedLoadResults().exists()).toBe(false);
      });

      it('calls `axios.get` with `projectsFetchPath` and query param `search`', async () => {
        jest.spyOn(axios, 'get');

        findSearchBox().vm.$emit('input', 'foo');
        await waitForPromises();

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
        jest.spyOn(axios, 'get');

        findSearchBox().vm.$emit('input', 'foo');
        await waitForPromises();

        expect(findAllDropdownItems()).toHaveLength(mockProjects.length);
        expect(focusInputMock).toHaveBeenCalled();
      });

      it('sets projectsListLoadFailed to true when request fails', async () => {
        jest.spyOn(axios, 'get').mockRejectedValue({});

        findSearchBox().vm.$emit('input', 'foo');
        await waitForPromises();

        expect(findFailedLoadResults().exists()).toBe(true);
      });

      it('sets projectsListLoading to false when request completes', async () => {
        jest.spyOn(axios, 'get');

        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('isSelectedProject', () => {
      it.each`
        projectIndex | selectedProjectIndex | title                       | returnValue
        ${0}         | ${0}                 | ${'are same projects'}      | ${true}
        ${0}         | ${1}                 | ${'are different projects'} | ${false}
      `(
        'returns $returnValue when selectedProject and provided project param $title',
        async ({ projectIndex, selectedProjectIndex, returnValue }) => {
          findDropdownEl().vm.$emit('shown');
          await waitForPromises();

          findAllDropdownItems().at(selectedProjectIndex).vm.$emit('click', mockEvent);

          await nextTick();

          expect(findAllDropdownItems().at(projectIndex).props('isChecked')).toBe(returnValue);
        },
      );

      it('returns false when selectedProject is null', async () => {
        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        expect(findAllDropdownItems().at(0).props('isChecked')).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders collapsed state element with icon', () => {
      const collapsedEl = findCollapsedEl();

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

      it('renders disabled dropdown when `disabled` is true', () => {
        createComponent({ ...mockProps, disabled: true });
        expect(findDropdownEl().props('disabled')).toBe(true);
      });

      it('renders header element', () => {
        const headerEl = findHeader();

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
        findDropdownEl().vm.$emit('shown');
        await nextTick();

        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('renders gl-dropdown-item components for available projects', async () => {
        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        findAllDropdownItems().at(0).vm.$emit('click', mockEvent);
        await nextTick();

        expect(findAllDropdownItems()).toHaveLength(mockProjects.length);
        expect(findAllDropdownItems().at(0).props()).toMatchObject({
          isCheckItem: true,
          isChecked: true,
        });
        expect(findAllDropdownItems().at(0).text()).toBe(mockProjects[0].name_with_namespace);
      });

      it('renders string "No matching results" when search does not yield any matches', async () => {
        mock.onGet(mockProps.projectsFetchPath).reply(HTTP_STATUS_OK, []);

        findSearchBox().vm.$emit('input', 'foo');
        await waitForPromises();

        expect(findDropdownContent().text()).toContain('No matching results');
      });

      it('renders string "Failed to load projects" when loading projects list fails', async () => {
        mock.onGet(mockProps.projectsFetchPath).reply(HTTP_STATUS_OK, []);
        jest.spyOn(axios, 'get').mockRejectedValue({});

        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        expect(findDropdownContent().text()).toContain('Failed to load projects');
      });

      it('renders gl-button within footer', async () => {
        const moveButtonEl = findFooter().findComponent(GlButton);

        expect(moveButtonEl.text()).toBe('Move');
        expect(moveButtonEl.attributes('disabled')).toBe('true');

        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        findAllDropdownItems().at(0).vm.$emit('click', mockEvent);
        await nextTick();

        expect(findFooter().findComponent(GlButton).attributes('disabled')).not.toBeDefined();
      });
    });

    describe('events', () => {
      it('collapsed state element emits `toggle-collapse` event on component when clicked', () => {
        findCollapsedEl().trigger('click');

        expect(wrapper.emitted('toggle-collapse')).toHaveLength(1);
      });

      it('gl-dropdown component calls `fetchProjects` on `shown` event', () => {
        jest.spyOn(axios, 'get');

        findDropdownEl().vm.$emit('shown');

        expect(axios.get).toHaveBeenCalled();
      });

      it('gl-dropdown component prevents dropdown body from closing on `hide` event when `projectItemClick` prop is true', async () => {
        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        findAllDropdownItems().at(0).vm.$emit('click', mockEvent);
        await nextTick();

        findDropdownEl().vm.$emit('hide', mockEvent);

        expect(mockEvent.preventDefault).toHaveBeenCalled();
      });

      it('gl-dropdown component emits `dropdown-close` event on component from `hide` event', () => {
        findDropdownEl().vm.$emit('hide');

        expect(wrapper.emitted('dropdown-close')).toHaveLength(1);
      });

      it('close icon in dropdown header closes the dropdown when clicked', async () => {
        findHeader().findComponent(GlButton).vm.$emit('click', mockEvent);

        await nextTick();
        expect(hideMock).toHaveBeenCalled();
      });

      it('sets project for clicked gl-dropdown-item to selectedProject', async () => {
        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        findAllDropdownItems().at(0).vm.$emit('click', mockEvent);
        await nextTick();

        expect(findAllDropdownItems().at(0).props('isChecked')).toBe(true);
      });

      it('hides dropdown and emits `move-issuable` event when move button is clicked', async () => {
        findDropdownEl().vm.$emit('shown');
        await waitForPromises();

        findAllDropdownItems().at(0).vm.$emit('click', mockEvent);
        await nextTick();

        findFooter().findComponent(GlButton).vm.$emit('click');

        expect(hideMock).toHaveBeenCalled();
        expect(wrapper.emitted('move-issuable')).toHaveLength(1);
        expect(wrapper.emitted('move-issuable')[0]).toEqual([mockProjects[0]]);
      });
    });
  });
});
