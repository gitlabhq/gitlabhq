import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import FrequentItems from '~/super_sidebar/components/global_search/components/frequent_items.vue';
import FrequentGroups from '~/super_sidebar/components/global_search/components/frequent_groups.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import currentUserFrecentGroupsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_groups.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { frecentGroupsMock } from '../../../mock_data';

Vue.use(VueApollo);

const TEST_GROUPS_PATH = '/mock/group/path';

describe('FrequentlyVisitedGroups', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;
  /** @type {jest.Mock} */
  let currentUserFrecentGroupsQueryHandler;

  const createComponent = (options) => {
    const mockApollo = createMockApollo([
      [currentUserFrecentGroupsQuery, currentUserFrecentGroupsQueryHandler],
    ]);

    wrapper = shallowMount(FrequentGroups, {
      apolloProvider: mockApollo,
      provide: {
        groupsPath: TEST_GROUPS_PATH,
      },
      ...options,
    });
  };

  const findFrequentItems = () => wrapper.findComponent(FrequentItems);
  const receivedAttrs = (wrapperInstance) => ({
    // See https://github.com/vuejs/test-utils/issues/2151.
    ...wrapperInstance.vm.$attrs,
  });

  beforeEach(() => {
    currentUserFrecentGroupsQueryHandler = jest.fn().mockResolvedValue({
      data: {
        frecentGroups: frecentGroupsMock,
      },
    });
  });

  it('passes group-specific props', () => {
    createComponent();

    expect(findFrequentItems().props()).toMatchObject({
      emptyStateText: 'Groups you visit often will appear here.',
      groupName: 'Frequently visited groups',
      viewAllItemsIcon: 'group',
      viewAllItemsText: 'View all my groups',
      viewAllItemsPath: TEST_GROUPS_PATH,
    });
  });

  it('loads frecent groups', () => {
    createComponent();

    expect(currentUserFrecentGroupsQueryHandler).toHaveBeenCalled();
    expect(findFrequentItems().props('loading')).toBe(true);
  });

  it('passes fetched groups to FrequentItems', async () => {
    createComponent();
    await waitForPromises();

    expect(findFrequentItems().props('items')).toEqual(frecentGroupsMock);
    expect(findFrequentItems().props('loading')).toBe(false);
  });

  it('passes attrs to FrequentItems', () => {
    createComponent({ attrs: { bordered: true, class: 'test-class' } });

    expect(findFrequentItems().classes()).toContain('test-class');
    expect(receivedAttrs(findFrequentItems())).toMatchObject({
      bordered: true,
    });
  });

  it('forwards listeners to FrequentItems', () => {
    const spy = jest.fn();
    createComponent({ listeners: { 'nothing-to-render': spy } });

    findFrequentItems().vm.$emit('nothing-to-render');

    expect(spy).toHaveBeenCalledTimes(1);
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits action on click', () => {
      findFrequentItems().vm.$emit('action');
      expect(wrapper.emitted('action')).toStrictEqual([['FREQUENTLY_VISITED_GROUPS_HANDLE']]);
    });
  });

  describe('when query returns null', () => {
    beforeEach(async () => {
      currentUserFrecentGroupsQueryHandler = jest.fn().mockResolvedValue({
        data: {
          frecentGroups: null,
        },
      });

      createComponent();

      await waitForPromises();
    });

    it('renders with empty array', () => {
      expect(findFrequentItems().props('items')).toEqual([]);
    });
  });
});
