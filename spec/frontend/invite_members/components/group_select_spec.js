import { nextTick } from 'vue';
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import waitForPromises from 'helpers/wait_for_promises';
import { getGroups } from '~/api/groups_api';
import GroupSelect from '~/invite_members/components/group_select.vue';

jest.mock('~/api/groups_api');

const group1 = { id: 1, full_name: 'Group One', avatar_url: 'test' };
const group2 = { id: 2, full_name: 'Group Two', avatar_url: 'test' };
const allGroups = [group1, group2];
const headers = {
  'X-Next-Page': 2,
  'X-Page': 1,
  'X-Per-Page': 20,
  'X-Prev-Page': '',
  'X-Total': 40,
  'X-Total-Pages': 2,
};

describe('GroupSelect', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(GroupSelect, {
      propsData: {
        selectedGroup: {},
        invalidGroups: [],
        ...props,
      },
    });
  };

  beforeEach(() => {
    getGroups.mockResolvedValueOnce({ data: allGroups, headers });
  });

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxToggle = () => findListbox().find('button[aria-haspopup="listbox"]');
  const findAvatarByLabel = (text) =>
    wrapper
      .findAllComponents(GlAvatarLabeled)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.props('label') === text);

  describe('when user types in the search input', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      getGroups.mockClear();
      getGroups.mockReturnValueOnce(new Promise(() => {}));
      findListbox().vm.$emit('search', group1.full_name);
      await nextTick();
    });

    it('calls the API', () => {
      expect(getGroups).toHaveBeenCalledWith(
        group1.full_name,
        {
          exclude_internal: true,
          active: true,
          order_by: 'similarity',
        },
        undefined,
        {
          signal: expect.any(AbortSignal),
        },
      );
    });

    it('displays loading icon while waiting for API call to resolve', () => {
      expect(findListbox().props('searching')).toBe(true);
    });
  });

  describe('avatar label', () => {
    it('includes the correct attributes with name and avatar_url', async () => {
      createComponent();
      await waitForPromises();

      expect(findAvatarByLabel(group1.full_name).attributes()).toMatchObject({
        src: group1.avatar_url,
        'entity-id': `${group1.id}`,
        'entity-name': group1.full_name,
        size: '32',
      });
    });

    describe('when filtering out the group from results', () => {
      beforeEach(async () => {
        createComponent({ invalidGroups: [group1.id] });
        await waitForPromises();
      });

      it('does not find an invalid group', () => {
        expect(findAvatarByLabel(group1.full_name)).toBe(undefined);
      });

      it('finds a group that is valid', () => {
        expect(findAvatarByLabel(group2.full_name).exists()).toBe(true);
      });
    });
  });

  describe('when group is selected from the dropdown', () => {
    beforeEach(async () => {
      createComponent({
        selectedGroup: {
          value: group1.id,
          id: group1.id,
          name: group1.full_name,
          path: group1.path,
          avatarUrl: group1.avatar_url,
        },
      });
      await waitForPromises();
      findListbox().vm.$emit('select', group1.id);
      await nextTick();
    });

    it('emits `input` event used by `v-model`', () => {
      expect(wrapper.emitted('input')).toMatchObject([
        [
          {
            value: group1.id,
            id: group1.id,
            name: group1.full_name,
            path: group1.path,
            avatarUrl: group1.avatar_url,
          },
        ],
      ]);
    });

    it('sets dropdown toggle text to selected item', () => {
      expect(findListboxToggle().text()).toBe(group1.full_name);
    });
  });

  describe('infinite scroll', () => {
    it('sets infinite scroll related props', async () => {
      createComponent();
      await waitForPromises();

      expect(findListbox().props()).toMatchObject({
        infiniteScroll: true,
        infiniteScrollLoading: false,
        totalItems: 40,
      });
    });

    describe('when `bottom-reached` event is fired', () => {
      it('indicates new groups are loading and adds them to the listbox', async () => {
        createComponent();
        await waitForPromises();

        const infiniteScrollGroup = {
          id: 3,
          full_name: 'Infinite scroll group',
          avatar_url: 'test',
        };

        getGroups.mockResolvedValueOnce({ data: [infiniteScrollGroup], headers });

        findListbox().vm.$emit('bottom-reached');
        await nextTick();

        expect(findListbox().props('infiniteScrollLoading')).toBe(true);

        await waitForPromises();

        expect(findListbox().props('items')[2]).toMatchObject({
          value: infiniteScrollGroup.id,
          id: infiniteScrollGroup.id,
          name: infiniteScrollGroup.full_name,
          avatarUrl: infiniteScrollGroup.avatar_url,
        });
      });

      describe('when API request fails', () => {
        it('emits `error` event', async () => {
          createComponent();
          await waitForPromises();

          getGroups.mockRejectedValueOnce();

          findListbox().vm.$emit('bottom-reached');
          await waitForPromises();

          expect(wrapper.emitted('error')).toEqual([[GroupSelect.i18n.errorMessage]]);
        });

        it('does not emit `error` event if error is from request cancellation', async () => {
          createComponent();
          await waitForPromises();

          getGroups.mockRejectedValueOnce(new axios.Cancel());

          findListbox().vm.$emit('bottom-reached');
          await waitForPromises();

          expect(wrapper.emitted('error')).toEqual(undefined);
        });
      });
    });
  });

  describe('when multiple API calls are in-flight', () => {
    it('aborts the first API call and resolves second API call', async () => {
      const abortSpy = jest.spyOn(AbortController.prototype, 'abort');

      createComponent();
      await waitForPromises();

      findListbox().vm.$emit('search', group1.full_name);

      expect(abortSpy).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted('error')).toEqual(undefined);
    });
  });
});
