import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import { MOCK_SEARCH_CONTEXT, MOCK_DEFAULT_SEARCH_OPTIONS } from '../mock_data';
import { contextSwitcherLinks } from '../../../mock_data';

Vue.use(Vuex);

describe('GlobalSearchDefaultItems', () => {
  let wrapper;

  const createComponent = ({
    storeState,
    mockDefaultSearchOptions = MOCK_DEFAULT_SEARCH_OPTIONS,
    ...options
  } = {}) => {
    const store = new Vuex.Store({
      state: {
        searchContext: MOCK_SEARCH_CONTEXT,
        ...storeState,
      },
      getters: {
        defaultSearchOptions: () => mockDefaultSearchOptions,
      },
    });

    wrapper = shallowMountExtended(GlobalSearchDefaultItems, {
      store,
      provide: {
        contextSwitcherLinks,
      },
      stubs: {
        GlDisclosureDropdownGroup,
      },
      ...options,
    });
  };

  const findGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findItems = (root = wrapper) => root.findAllComponents(GlDisclosureDropdownItem);

  describe('template', () => {
    describe('Dropdown items', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders two groups', () => {
        const groups = findGroups();

        expect(groups).toHaveLength(2);

        const actualNames = groups.wrappers.map((group) => group.props('group').name);
        expect(actualNames).toEqual(['Places', 'All GitLab']);
      });

      it('renders context switcher links in first group', () => {
        const group = findGroups().at(0);
        expect(group.props('group').name).toBe('Places');

        const items = findItems(group);
        expect(items).toHaveLength(contextSwitcherLinks.length);
      });

      it('renders default search options in second group', () => {
        const group = findGroups().at(1);
        expect(group.props('group').name).toBe('All GitLab');

        const items = findItems(group);
        expect(items).toHaveLength(MOCK_DEFAULT_SEARCH_OPTIONS.length);
      });
    });

    describe('Empty groups', () => {
      beforeEach(() => {
        createComponent({ mockDefaultSearchOptions: [], provide: { contextSwitcherLinks: [] } });
      });

      it('does not render groups with no items', () => {
        expect(findGroups()).toHaveLength(0);
      });
    });

    describe.each`
      group                     | project                     | groupHeader
      ${null}                   | ${null}                     | ${'All GitLab'}
      ${{ name: 'Test Group' }} | ${null}                     | ${'Test Group'}
      ${{ name: 'Test Group' }} | ${{ name: 'Test Project' }} | ${'Test Project'}
    `('Current context header', ({ group, project, groupHeader }) => {
      describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
        beforeEach(() => {
          createComponent({
            storeState: {
              searchContext: {
                group,
                project,
              },
            },
          });
        });

        it(`should render as ${groupHeader}`, () => {
          expect(wrapper.text()).toContain(groupHeader);
        });
      });
    });
  });
});
