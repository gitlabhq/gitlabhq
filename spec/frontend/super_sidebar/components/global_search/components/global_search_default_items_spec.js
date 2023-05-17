import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import { MOCK_SEARCH_CONTEXT, MOCK_DEFAULT_SEARCH_OPTIONS } from '../mock_data';

Vue.use(Vuex);

describe('GlobalSearchDefaultItems', () => {
  let wrapper;

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        searchContext: MOCK_SEARCH_CONTEXT,
        ...initialState,
      },
      getters: {
        defaultSearchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
      },
    });

    wrapper = shallowMountExtended(GlobalSearchDefaultItems, {
      store,
      propsData: {
        ...props,
      },
      stubs: {
        GlDisclosureDropdownGroup,
      },
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findItemsData = () => findItems().wrappers.map((w) => w.props('item'));

  describe('template', () => {
    describe('Dropdown items', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders item for each option in defaultSearchOptions', () => {
        expect(findItems()).toHaveLength(MOCK_DEFAULT_SEARCH_OPTIONS.length);
      });

      it('provides the `item` prop to the `GlDisclosureDropdownItem` component', () => {
        expect(findItemsData()).toStrictEqual(MOCK_DEFAULT_SEARCH_OPTIONS);
      });
    });

    describe.each`
      group                     | project                     | groupHeader
      ${null}                   | ${null}                     | ${'All GitLab'}
      ${{ name: 'Test Group' }} | ${null}                     | ${'Test Group'}
      ${{ name: 'Test Group' }} | ${{ name: 'Test Project' }} | ${'Test Project'}
    `('Group Header', ({ group, project, groupHeader }) => {
      describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
        beforeEach(() => {
          createComponent({
            searchContext: {
              group,
              project,
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
