import { mount, shallowMount } from '@vue/test-utils';
import { GlAvatarLabeled, GlBadge, GlTableLite } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import PlaceholdersTable from '~/members/components/placeholders/placeholders_table.vue';
import { mockPlaceholderUsers } from './mock_data';

describe('PlaceholdersTable', () => {
  let wrapper;

  const defaultProps = {
    items: mockPlaceholderUsers,
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(PlaceholdersTable, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableFields = () =>
    findTable()
      .props('fields')
      .map((f) => f.label);

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findBadgeTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  it('renders table', () => {
    createComponent();

    expect(findTable().exists()).toBe(true);
    expect(findTableFields()).toEqual([
      'Placeholder user',
      'Source',
      'Reassignment status',
      'Reassign placeholder to',
    ]);
  });

  it('renders avatar', () => {
    createComponent({ mountFn: mount });

    const avatar = findTable().findComponent(GlAvatarLabeled);

    expect(avatar.props()).toMatchObject({
      label: mockPlaceholderUsers[0].name,
      subLabel: mockPlaceholderUsers[0].username,
    });
    expect(avatar.attributes('src')).toBe(mockPlaceholderUsers[0].avatar_url);
  });

  it('renders source info', () => {
    createComponent({ mountFn: mount });

    expect(findTable().find('tbody tr').text()).toContain(mockPlaceholderUsers[0].source_hostname);
  });

  it('renders status badge with tooltip', () => {
    createComponent({ mountFn: mount });

    expect(findBadge().text()).toBe('Not started');
    expect(findBadgeTooltip().value).toBe('Reassignment has not started.');
  });

  describe('when is "Re-assigned" table variant', () => {
    beforeEach(() => {
      createComponent({
        props: {
          reassigned: true,
        },
      });
    });

    it('renders table', () => {
      expect(findTable().exists()).toBe(true);
      expect(findTableFields()).toEqual([
        'Placeholder user',
        'Source',
        'Reassignment status',
        'Reassigned to',
      ]);
    });
  });
});
