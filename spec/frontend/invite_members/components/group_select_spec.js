import { nextTick } from 'vue';
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import waitForPromises from 'helpers/wait_for_promises';
import { getGroups } from '~/api/groups_api';
import { getProjectShareLocations } from '~/api/projects_api';
import GroupSelect from '~/invite_members/components/group_select.vue';

jest.mock('~/api/groups_api');
jest.mock('~/api/projects_api');

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

const defaultProps = {
  selectedGroup: {},
  invalidGroups: [],
  sourceId: '1',
  isProject: false,
};

describe('GroupSelect', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(GroupSelect, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxToggle = () => findListbox().find('button[aria-haspopup="listbox"]');
  const findAvatarByLabel = (text) =>
    wrapper
      .findAllComponents(GlAvatarLabeled)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.props('label') === text);

  describe('when user types in the search input', () => {
    describe('isProject is false', () => {
      beforeEach(async () => {
        createComponent({ isProject: false });
        await waitForPromises();

        getGroups.mockReturnValueOnce(new Promise(() => {}));
        findListbox().vm.$emit('search', group1.full_name);
      });

      it('displays loading icon while waiting for API call to resolve', () => {
        expect(findListbox().props('searching')).toBe(true);
      });

      it('calls the legacy API', async () => {
        await nextTick();

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
    });

    describe('isProject is true', () => {
      beforeEach(async () => {
        createComponent({ isProject: true });
        await waitForPromises();

        getProjectShareLocations.mockReturnValueOnce(new Promise(() => {}));
        findListbox().vm.$emit('search', group1.full_name);
      });

      it('displays loading icon while waiting for API call to resolve', () => {
        expect(findListbox().props('searching')).toBe(true);
      });

      it('calls the new API', async () => {
        await nextTick();

        expect(getProjectShareLocations).toHaveBeenCalledWith(
          defaultProps.sourceId,
          {
            search: group1.full_name,
          },
          {
            signal: expect.any(AbortSignal),
          },
        );
      });
    });
  });

  describe.each`
    isProject
    ${true}
    ${false}
  `('isProject is $isProject', ({ isProject }) => {
    const apiAction = isProject ? getProjectShareLocations : getGroups;

    beforeEach(() => {
      apiAction.mockResolvedValueOnce({ data: allGroups, headers });
    });

    describe('avatar label', () => {
      it('includes the correct attributes with name and avatar_url', async () => {
        createComponent({ isProject });
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
          createComponent({ isProject, invalidGroups: [group1.id] });
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
          isProject,
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
      beforeEach(async () => {
        createComponent({ isProject });
        await waitForPromises();
      });

      it('sets infinite scroll related props', () => {
        expect(findListbox().props()).toMatchObject({
          infiniteScroll: true,
          infiniteScrollLoading: false,
          totalItems: 40,
        });
      });

      describe('when `bottom-reached` event is fired', () => {
        it('indicates new groups are loading and adds them to the listbox', async () => {
          const infiniteScrollGroup = {
            id: 3,
            full_name: 'Infinite scroll group',
            avatar_url: 'test',
          };

          apiAction.mockResolvedValueOnce({ data: [infiniteScrollGroup], headers });

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

          if (isProject) {
            expect(apiAction).toHaveBeenCalledWith(
              defaultProps.sourceId,
              { search: '', page: 2 },
              {
                signal: expect.any(AbortSignal),
              },
            );
          } else {
            expect(apiAction).toHaveBeenCalledWith(
              '',
              expect.objectContaining({ page: 2 }),
              undefined,
              {
                signal: expect.any(AbortSignal),
              },
            );
          }
        });

        describe('when API request fails', () => {
          it('emits `error` event', async () => {
            apiAction.mockRejectedValueOnce();

            findListbox().vm.$emit('bottom-reached');
            await waitForPromises();

            expect(wrapper.emitted('error')).toEqual([[GroupSelect.i18n.errorMessage]]);
          });

          it('does not emit `error` event if error is from request cancellation', async () => {
            apiAction.mockRejectedValueOnce(new axios.Cancel());

            findListbox().vm.$emit('bottom-reached');
            await waitForPromises();

            expect(wrapper.emitted('error')).toEqual(undefined);
          });
        });
      });
    });

    describe('when multiple API calls are in-flight', () => {
      let abortSpy;

      beforeEach(async () => {
        abortSpy = jest.spyOn(AbortController.prototype, 'abort');
        apiAction.mockResolvedValueOnce({ data: allGroups, headers });

        createComponent({ isProject });
        await waitForPromises();
      });

      it('aborts the first API call and resolves second API call', () => {
        findListbox().vm.$emit('search', group1.full_name);

        expect(abortSpy).toHaveBeenCalledTimes(1);
        expect(wrapper.emitted('error')).toEqual(undefined);
      });
    });
  });
});
