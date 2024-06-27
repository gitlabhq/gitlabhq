import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount, shallowMount } from '@vue/test-utils';
import { GlAvatarLabeled, GlBadge, GlTableLite } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';

import PlaceholdersTable from '~/members/components/placeholders/placeholders_table.vue';
import PlaceholderActions from '~/members/components/placeholders/placeholder_actions.vue';
import { mockPlaceholderUsers } from './mock_data';

Vue.use(VueApollo);

describe('PlaceholdersTable', () => {
  let wrapper;
  let mockApollo;

  const defaultProps = {
    items: mockPlaceholderUsers,
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    mockApollo = createMockApollo();

    wrapper = mountFn(PlaceholdersTable, {
      apolloProvider: mockApollo,
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
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findTableFields = () =>
    findTable()
      .props('fields')
      .map((f) => f.label);

  it('renders table', () => {
    createComponent({ mountFn: mount });

    expect(findTable().exists()).toBe(true);
    expect(findTableRows().length).toBe(mockPlaceholderUsers.length);
    expect(findTableFields()).toEqual([
      'Placeholder user',
      'Source',
      'Reassignment status',
      'Reassign placeholder to',
    ]);
  });

  it('renders avatar', () => {
    createComponent({ mountFn: mount });

    const avatar = findTableRows().at(0).findComponent(GlAvatarLabeled);

    expect(avatar.props()).toMatchObject({
      label: mockPlaceholderUsers[0].name,
      subLabel: mockPlaceholderUsers[0].username,
    });
    expect(avatar.attributes('src')).toBe(mockPlaceholderUsers[0].avatar_url);
  });

  it('renders source info', () => {
    createComponent({ mountFn: mount });

    expect(findTableRows().at(0).text()).toContain(mockPlaceholderUsers[0].source_hostname);
  });

  it('renders status badge with tooltip', () => {
    createComponent({ mountFn: mount });

    const firstRow = findTableRows().at(0);
    const badge = firstRow.findComponent(GlBadge);
    const badgeTooltip = getBinding(badge.element, 'gl-tooltip');

    expect(badge.text()).toBe('Not started');
    expect(badgeTooltip.value).toBe('Reassignment has not started.');
  });

  it('renders actions when item is not reassigned', () => {
    createComponent({ mountFn: mount });

    const firstRow = findTableRows().at(0);
    const actions = firstRow.findComponent(PlaceholderActions);

    expect(actions.props('placeholder')).toEqual(mockPlaceholderUsers[0]);
  });

  it('renders avatar of final user when item is reassigned', () => {
    createComponent({ mountFn: mount });

    const reassignedItemRow = findTableRows().at(5);
    const actionsAvatar = reassignedItemRow.findAllComponents(GlAvatarLabeled).at(1);

    expect(actionsAvatar.props()).toMatchObject({
      label: mockPlaceholderUsers[5].reassignToUser.name,
      subLabel: mockPlaceholderUsers[5].reassignToUser.username,
    });
  });

  describe('actions events', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it('emits "confirm" event with item and selectedUserId', () => {
      const selectedUserId = 647;
      const actions = findTableRows().at(2).findComponent(PlaceholderActions);

      actions.vm.$emit('confirm', selectedUserId);

      expect(wrapper.emitted('confirm')[0]).toEqual([mockPlaceholderUsers[2], selectedUserId]);
    });

    it('emits "cancel" event with item and selectedUserId', () => {
      const actions = findTableRows().at(2).findComponent(PlaceholderActions);

      actions.vm.$emit('cancel');

      expect(wrapper.emitted('cancel')[0]).toEqual([mockPlaceholderUsers[2]]);
    });
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
