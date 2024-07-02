import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount, shallowMount } from '@vue/test-utils';
import { GlAvatarLabeled, GlBadge, GlKeysetPagination, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';

import PlaceholdersTable from '~/members/components/placeholders/placeholders_table.vue';
import PlaceholderActions from '~/members/components/placeholders/placeholder_actions.vue';
import { mockSourceUsers } from './mock_data';

Vue.use(VueApollo);

describe('PlaceholdersTable', () => {
  let wrapper;
  let mockApollo;

  const defaultProps = {
    isLoading: false,
    items: mockSourceUsers,
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

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findTableFields = () =>
    findTable()
      .props('fields')
      .map((f) => f.label);

  it('renders table', () => {
    createComponent({ mountFn: mount });

    expect(findTable().exists()).toBe(true);
    expect(findTableRows().length).toBe(mockSourceUsers.length);
    expect(findTableFields()).toEqual([
      'Placeholder user',
      'Source',
      'Reassignment status',
      'Reassign placeholder to',
    ]);
  });

  it('renders loading icon when table is loading', () => {
    createComponent({
      props: { isLoading: true },
    });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders avatar for placeholder user', () => {
    createComponent({ mountFn: mount });

    const avatar = findTableRows().at(0).findComponent(GlAvatarLabeled);
    const { placeholderUser } = mockSourceUsers[0];

    expect(avatar.props()).toMatchObject({
      label: placeholderUser.name,
      subLabel: `@${placeholderUser.username}`,
    });
    expect(avatar.attributes('src')).toBe(placeholderUser.avatarUrl);
  });

  it('renders source info', () => {
    createComponent({ mountFn: mount });

    expect(findTableRows().at(0).text()).toContain(mockSourceUsers[0].sourceHostname);
    expect(findTableRows().at(0).text()).toContain(mockSourceUsers[0].sourceUsername);
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

    expect(actions.props('placeholder')).toEqual(mockSourceUsers[0]);
  });

  it('renders avatar for final user when item is reassigned', () => {
    createComponent({ mountFn: mount });

    const reassignedItemRow = findTableRows().at(5);
    const actionsAvatar = reassignedItemRow.findAllComponents(GlAvatarLabeled).at(1);
    const { reassignToUser } = mockSourceUsers[5];

    expect(actionsAvatar.props()).toMatchObject({
      label: reassignToUser.name,
      subLabel: `@${reassignToUser.username}`,
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

      expect(wrapper.emitted('confirm')[0]).toEqual([mockSourceUsers[2], selectedUserId]);
    });

    it('emits "cancel" event with item and selectedUserId', () => {
      const actions = findTableRows().at(2).findComponent(PlaceholderActions);

      actions.vm.$emit('cancel');

      expect(wrapper.emitted('cancel')[0]).toEqual([mockSourceUsers[2]]);
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

  describe('pagination', () => {
    describe.each`
      hasNextPage | hasPreviousPage | expectPagination
      ${false}    | ${false}        | ${false}
      ${false}    | ${true}         | ${true}
      ${true}     | ${false}        | ${true}
      ${true}     | ${true}         | ${true}
    `(
      'when hasNextPage=$hasNextPage and hasPreviousPage=$hasPreviousPage',
      ({ hasNextPage, hasPreviousPage, expectPagination }) => {
        beforeEach(() => {
          createComponent({
            props: {
              pageInfo: {
                hasNextPage,
                hasPreviousPage,
              },
            },
          });
        });

        it(`${expectPagination ? 'renders' : 'does not render'} pagination`, () => {
          expect(findPagination().exists()).toBe(expectPagination);
        });
      },
    );

    it('emits "prev" event', () => {
      createComponent({
        props: {
          pageInfo: {
            hasPreviousPage: true,
          },
        },
      });

      findPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev')[0]).toEqual([]);
    });

    it('emits "next" event', () => {
      createComponent({
        props: {
          pageInfo: {
            hasNextPage: true,
          },
        },
      });

      findPagination().vm.$emit('next');

      expect(wrapper.emitted('next')[0]).toEqual([]);
    });
  });
});
