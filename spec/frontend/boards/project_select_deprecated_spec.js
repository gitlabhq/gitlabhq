import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import ProjectSelect from '~/boards/components/project_select_deprecated.vue';
import { ListType } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import createFlash from '~/flash';
import httpStatus from '~/lib/utils/http_status';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';

import { listObj, mockRawGroupProjects } from './mock_data';

jest.mock('~/boards/eventhub');
jest.mock('~/flash');

const dummyGon = {
  api_version: 'v4',
  relative_url_root: '/gitlab',
};

const mockGroupId = 1;
const mockProjectsList1 = mockRawGroupProjects.slice(0, 1);
const mockProjectsList2 = mockRawGroupProjects.slice(1);
const mockDefaultFetchOptions = {
  with_issues_enabled: true,
  with_shared: false,
  include_subgroups: true,
  order_by: 'similarity',
  archived: false,
};

const itemsPerPage = 20;

describe('ProjectSelect component', () => {
  let wrapper;
  let axiosMock;

  const findLabel = () => wrapper.find("[data-testid='header-label']");
  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownLoadingIcon = () =>
    findGlDropdown().find('button:first-child').find(GlLoadingIcon);
  const findGlSearchBoxByType = () => wrapper.find(GlSearchBoxByType);
  const findGlDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findFirstGlDropdownItem = () => findGlDropdownItems().at(0);
  const findInMenuLoadingIcon = () => wrapper.find("[data-testid='dropdown-text-loading-icon']");
  const findEmptySearchMessage = () => wrapper.find("[data-testid='empty-result-message']");

  const mockGetRequest = (data = [], statusCode = httpStatus.OK) => {
    axiosMock
      .onGet(`/gitlab/api/v4/groups/${mockGroupId}/projects.json`)
      .replyOnce(statusCode, data);
  };

  const searchForProject = async (keyword, waitForAll = true) => {
    findGlSearchBoxByType().vm.$emit('input', keyword);

    if (waitForAll) {
      await axios.waitForAll();
    }
  };

  const createWrapper = async ({ list = listObj } = {}, waitForAll = true) => {
    wrapper = mount(ProjectSelect, {
      propsData: {
        list,
      },
      provide: {
        groupId: 1,
      },
    });

    if (waitForAll) {
      await axios.waitForAll();
    }
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    window.gon = dummyGon;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    axiosMock.restore();
    jest.clearAllMocks();
  });

  it('displays a header title', async () => {
    createWrapper({});

    expect(findLabel().text()).toBe('Projects');
  });

  it('renders a default dropdown text', async () => {
    createWrapper({});

    expect(findGlDropdown().exists()).toBe(true);
    expect(findGlDropdown().text()).toContain('Select a project');
  });

  describe('when mounted', () => {
    it('displays a loading icon while projects are being fetched', async () => {
      mockGetRequest([]);

      createWrapper({}, false);

      expect(findGlDropdownLoadingIcon().exists()).toBe(true);

      await axios.waitForAll();

      expect(axiosMock.history.get[0].params).toMatchObject({ search: '' });
      expect(axiosMock.history.get[0].url).toBe(
        `/gitlab/api/v4/groups/${mockGroupId}/projects.json`,
      );

      expect(findGlDropdownLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when dropdown menu is open', () => {
    describe('by default', () => {
      beforeEach(async () => {
        mockGetRequest(mockProjectsList1);

        await createWrapper();
      });

      it('shows GlSearchBoxByType with default attributes', () => {
        expect(findGlSearchBoxByType().exists()).toBe(true);
        expect(findGlSearchBoxByType().vm.$attrs).toMatchObject({
          placeholder: 'Search projects',
          debounce: '250',
        });
      });

      it("displays the fetched project's name", () => {
        expect(findFirstGlDropdownItem().exists()).toBe(true);
        expect(findFirstGlDropdownItem().text()).toContain(mockProjectsList1[0].name);
      });

      it("doesn't render loading icon in the menu", () => {
        expect(findInMenuLoadingIcon().isVisible()).toBe(false);
      });

      it('renders empty search result message', async () => {
        await createWrapper();

        expect(findEmptySearchMessage().exists()).toBe(true);
      });
    });

    describe('when a project is selected', () => {
      beforeEach(async () => {
        mockGetRequest(mockProjectsList1);

        await createWrapper();

        await findFirstGlDropdownItem().find('button').trigger('click');
      });

      it('emits setSelectedProject with correct project metadata', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith('setSelectedProject', {
          id: mockProjectsList1[0].id,
          path: mockProjectsList1[0].path_with_namespace,
          name: mockProjectsList1[0].name,
          namespacedName: mockProjectsList1[0].name_with_namespace,
        });
      });

      it('renders the name of the selected project', () => {
        expect(findGlDropdown().find('.gl-new-dropdown-button-text').text()).toBe(
          mockProjectsList1[0].name,
        );
      });
    });

    describe('when user searches for a project', () => {
      beforeEach(async () => {
        mockGetRequest(mockProjectsList1);

        await createWrapper();
      });

      it('calls API with correct parameters with default fetch options', async () => {
        await searchForProject('foobar');

        const expectedApiParams = {
          search: 'foobar',
          per_page: itemsPerPage,
          ...mockDefaultFetchOptions,
        };

        expect(axiosMock.history.get[1].params).toMatchObject(expectedApiParams);
        expect(axiosMock.history.get[1].url).toBe(
          `/gitlab/api/v4/groups/${mockGroupId}/projects.json`,
        );
      });

      describe("when list type is defined and isn't backlog", () => {
        it('calls API with an additional fetch option (min_access_level)', async () => {
          axiosMock.reset();

          await createWrapper({ list: { ...listObj, type: ListType.label } });

          await searchForProject('foobar');

          const expectedApiParams = {
            search: 'foobar',
            per_page: itemsPerPage,
            ...mockDefaultFetchOptions,
            min_access_level: featureAccessLevel.EVERYONE,
          };

          expect(axiosMock.history.get[1].params).toMatchObject(expectedApiParams);
          expect(axiosMock.history.get[1].url).toBe(
            `/gitlab/api/v4/groups/${mockGroupId}/projects.json`,
          );
        });
      });

      it('displays and hides gl-loading-icon while and after fetching data', async () => {
        await searchForProject('some keyword', false);

        await wrapper.vm.$nextTick();

        expect(findInMenuLoadingIcon().isVisible()).toBe(true);

        await axios.waitForAll();

        expect(findInMenuLoadingIcon().isVisible()).toBe(false);
      });

      it('flashes an error message when fetching fails', async () => {
        mockGetRequest([], httpStatus.INTERNAL_SERVER_ERROR);

        await searchForProject('foobar');

        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith({
          message: 'Something went wrong while fetching projects',
        });
      });

      describe('with non-empty search result', () => {
        beforeEach(async () => {
          mockGetRequest(mockProjectsList2);

          await searchForProject('foobar');
        });

        it('displays the retrieved list of projects', async () => {
          expect(findFirstGlDropdownItem().text()).toContain(mockProjectsList2[0].name);
        });

        it('does not render empty search result message', async () => {
          expect(findEmptySearchMessage().exists()).toBe(false);
        });
      });
    });
  });
});
