import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GlobalSearchDefaultPlaces from '~/super_sidebar/components/global_search/components/global_search_default_places.vue';
import SearchResultHoverLayover from '~/super_sidebar/components/global_search/components/global_search_hover_overlay.vue';
import { contextSwitcherLinks } from '../../../mock_data';

describe('GlobalSearchDefaultPlaces', () => {
  let wrapper;

  const createComponent = ({ links = [], attrs } = {}) => {
    wrapper = shallowMount(GlobalSearchDefaultPlaces, {
      provide: {
        contextSwitcherLinks: links,
      },
      attrs,
      stubs: {
        GlDisclosureDropdownGroup,
      },
    });
  };

  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findLayover = () => wrapper.findComponent(SearchResultHoverLayover);

  describe('given no contextSwitcherLinks', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });

    it('emits a nothing-to-render event', () => {
      expect(wrapper.emitted('nothing-to-render')).toEqual([[]]);
    });
  });

  describe('given some contextSwitcherLinks', () => {
    beforeEach(() => {
      createComponent({
        links: contextSwitcherLinks,
        attrs: {
          bordered: true,
          class: 'test-class',
        },
      });
    });

    it('renders a disclosure dropdown group', () => {
      expect(findGroup().exists()).toBe(true);
    });

    it('renders the expected header', () => {
      expect(wrapper.text()).toContain('Places');
    });

    it('passes attrs down', () => {
      const group = findGroup();
      expect(group.props('bordered')).toBe(true);
      expect(group.classes()).toContain('test-class');
    });

    it('renders the links', () => {
      const itemProps = findItems().wrappers.map((item) => item.props('item'));

      expect(itemProps).toEqual([
        {
          text: 'Explore',
          href: '/explore',
          extraAttrs: {
            class: 'show-hover-layover',
            'data-track-action': 'click_command_palette_item',
            'data-track-extra': '{"title":"Explore"}',
            'data-track-label': 'item_without_id',
            'data-track-property': 'nav_panel_unknown',
            'data-testid': 'places-item-link',
            'data-qa-places-item': 'Explore',
          },
        },
        {
          text: 'Admin area',
          href: '/admin',
          extraAttrs: {
            class: 'show-hover-layover',
            'data-track-action': 'click_command_palette_item',
            'data-track-extra': '{"title":"Admin area"}',
            'data-track-label': 'item_without_id',
            'data-track-property': 'nav_panel_unknown',
            'data-testid': 'places-item-link',
            'data-qa-places-item': 'Admin area',
          },
        },
        {
          text: 'Leave admin mode',
          href: '/admin/session/destroy',
          extraAttrs: {
            class: 'show-hover-layover',
            'data-track-action': 'click_command_palette_item',
            'data-track-extra': '{"title":"Leave admin mode"}',
            'data-track-label': 'item_without_id',
            'data-track-property': 'nav_panel_unknown',
            'data-testid': 'places-item-link',
            'data-qa-places-item': 'Leave admin mode',
            'data-method': 'post',
          },
        },
      ]);
    });

    it('renders the layover component', () => {
      expect(findLayover().exists()).toBe(true);
    });
  });
});
