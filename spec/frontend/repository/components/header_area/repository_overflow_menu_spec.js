import { RouterLinkStub } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RepositoryOverflowMenu from '~/repository/components/header_area/repository_overflow_menu.vue';

const defaultMockRoute = {
  params: {
    path: '/-/tree',
  },
  meta: {
    refType: '',
  },
  query: {
    ref_type: '',
  },
  name: 'treePathDecoded',
};

describe('RepositoryOverflowMenu', () => {
  let wrapper;

  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => x.props('item').text === text);
  const findCompareItem = () => findDropdownItemWithText('Compare');

  const createComponent = (route = {}, provide = {}) => {
    return shallowMountExtended(RepositoryOverflowMenu, {
      provide: {
        comparePath: null,
        ...provide,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      mocks: {
        $route: {
          ...defaultMockRoute,
          ...route,
        },
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  describe('Compare item', () => {
    it('does not render Compare button for root ref', () => {
      wrapper = createComponent({ params: { path: '/-/tree/new-branch-3' } });
      expect(findCompareItem()).toBeUndefined();
    });

    it('renders Compare button for non-root ref', () => {
      wrapper = createComponent(
        { params: { path: '/-/tree/new-branch-3' } },
        { comparePath: 'test/project/-/compare?from=master&to=new-branch-3' },
      );
      expect(findCompareItem().exists()).toBe(true);
      expect(findCompareItem().props('item')).toMatchObject({
        href: 'test/project/-/compare?from=master&to=new-branch-3',
      });
    });

    it('does not render compare button when comparePath is not provided', () => {
      wrapper = createComponent();
      expect(findCompareItem()).toBeUndefined();
    });
  });
});
