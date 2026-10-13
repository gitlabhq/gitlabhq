import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SoloOwnedGroupsList from '~/organizations/shared/components/solo_owned_groups_list.vue';
import soloOwnedGroupsQuery from '~/organizations/shared/graphql/queries/solo_owned_groups.query.graphql';

Vue.use(VueApollo);

describe('SoloOwnedGroupsList', () => {
  let wrapper;

  const createGroup = (index) => ({
    id: `gid://gitlab/Group/${index}`,
    fullPath: index === 1 ? 'acme' : `acme/group-${index}`,
    webPath: `/acme/group-${index}`,
    parent: index === 1 ? null : { id: 'gid://gitlab/Group/1' },
  });

  const createResponse = ({ count, from = 1, size = count, hasNextPage = false }) => ({
    data: {
      user: {
        id: 'gid://gitlab/User/1',
        groups: {
          count,
          nodes: Array.from({ length: size }, (_, index) => createGroup(from + index)),
          pageInfo: { hasNextPage, endCursor: `cursor-${from + size - 1}` },
        },
      },
    },
  });

  const createComponent = (
    handler,
    apolloProvider = createMockApollo([[soloOwnedGroupsQuery, handler]]),
  ) => {
    wrapper = mountExtended(SoloOwnedGroupsList, {
      propsData: { userId: 1, username: 'John Doe' },
      apolloProvider,
      slots: { help: 'Help message' },
    });
  };

  const findRows = () => wrapper.findAllByTestId('solo-owned-group');
  const findShowMoreButton = () => wrapper.findByTestId('show-more-groups');
  const findSoloOwnedGroupsAlert = () => wrapper.findByTestId('solo-owned-groups-alert');
  const findSoloOwnedGroupsHelp = () => wrapper.findByTestId('solo-owned-groups-help');
  const lastEmittedStatus = () => wrapper.emitted('change').at(-1)[0];

  describe('while loading', () => {
    beforeEach(() => {
      createComponent(jest.fn().mockReturnValue(new Promise(() => {})));
    });

    it('shows a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('emits a loading status', () => {
      expect(lastEmittedStatus()).toEqual({ loading: true, count: 0, error: false });
    });
  });

  describe('when the user owns no groups', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockResolvedValue(createResponse({ count: 0 })));
      await waitForPromises();
    });

    it('renders no list', () => {
      expect(wrapper.find('ul').exists()).toBe(false);
    });

    it('does not render the alert and help message', () => {
      expect(findSoloOwnedGroupsAlert().exists()).toBe(false);
      expect(findSoloOwnedGroupsHelp().exists()).toBe(false);
    });

    it('emits a status with no groups', () => {
      expect(lastEmittedStatus()).toEqual({ loading: false, count: 0, error: false });
    });
  });

  describe('when the user is the sole owner of a few groups', () => {
    const handler = jest.fn().mockResolvedValue(createResponse({ count: 3 }));

    beforeEach(async () => {
      createComponent(handler);
      await waitForPromises();
    });

    it('queries the solo owned groups of the user', () => {
      expect(handler).toHaveBeenCalledWith({ id: 'gid://gitlab/User/1', first: 5 });
    });

    it('renders a link for each group', () => {
      const links = wrapper.findAllComponents(GlLink);

      expect(links.wrappers.map((link) => [link.text(), link.attributes('href')])).toEqual([
        ['acme', '/acme/group-1'],
        ['acme/group-2', '/acme/group-2'],
        ['acme/group-3', '/acme/group-3'],
      ]);
    });

    it('renders a group icon for top-level groups and a subgroup icon for subgroups', () => {
      const icons = findRows().wrappers.map((row) => row.findComponent(GlIcon).props('name'));

      expect(icons).toEqual(['group', 'subgroup', 'subgroup']);
    });

    it('renders an alert with the username and number of groups', () => {
      expect(findSoloOwnedGroupsAlert().text()).toBe('John Doe is the sole owner of 3 groups');
    });

    it('renders the help slot', () => {
      expect(findSoloOwnedGroupsHelp().text()).toBe('Help message');
    });

    it('does not render the show more button', () => {
      expect(findShowMoreButton().exists()).toBe(false);
    });

    it('emits the group count', () => {
      expect(lastEmittedStatus()).toEqual({ loading: false, count: 3, error: false });
    });
  });

  describe('when the user is the current user', () => {
    beforeEach(async () => {
      window.gon.current_user_id = 1;
      createComponent(jest.fn().mockResolvedValue(createResponse({ count: 3 })));
      await waitForPromises();
    });

    it('renders an alert addressing the current user', () => {
      expect(findSoloOwnedGroupsAlert().text()).toBe('You are the sole owner of 3 groups');
    });
  });

  describe('when the user is the sole owner of more groups than initially shown', () => {
    let handler;

    beforeEach(async () => {
      handler = jest
        .fn()
        .mockResolvedValueOnce(createResponse({ count: 7, size: 5, hasNextPage: true }))
        .mockResolvedValueOnce(createResponse({ count: 7, from: 6, size: 2 }));
      createComponent(handler);
      await waitForPromises();
    });

    it('renders the first five groups', () => {
      expect(findRows()).toHaveLength(5);
    });

    it('renders the number of hidden groups', () => {
      expect(findShowMoreButton().text()).toBe('+2 more groups');
    });

    describe('when the show more button is clicked', () => {
      beforeEach(async () => {
        findShowMoreButton().trigger('click');
        await waitForPromises();
      });

      it('fetches the remaining groups', () => {
        expect(handler).toHaveBeenLastCalledWith({
          id: 'gid://gitlab/User/1',
          first: 100,
          after: 'cursor-5',
        });
      });

      it('renders all groups and hides the button', () => {
        expect(findRows()).toHaveLength(7);
        expect(findShowMoreButton().exists()).toBe(false);
      });
    });

    describe('when fetching the remaining groups fails', () => {
      beforeEach(async () => {
        handler.mockReset().mockRejectedValue(new Error('Network error'));
        findShowMoreButton().trigger('click');
        await waitForPromises();
      });

      it('shows an error alert', () => {
        expect(wrapper.findComponent(GlAlert).text()).toBe(
          'An error occurred while loading groups. Please try again.',
        );
      });

      it('emits an error status', () => {
        expect(lastEmittedStatus()).toEqual({ loading: false, count: 7, error: true });
      });
    });

    describe('when the user cannot be found while fetching the remaining groups', () => {
      beforeEach(async () => {
        handler.mockReset().mockResolvedValue({ data: { user: null } });
        findShowMoreButton().trigger('click');
        await waitForPromises();
      });

      it('shows an error alert', () => {
        expect(wrapper.findComponent(GlAlert).text()).toBe(
          'An error occurred while loading groups. Please try again.',
        );
      });
    });
  });

  describe('when the query fails', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockRejectedValue(new Error('Network error')));
      await waitForPromises();
    });

    it('shows an error alert', () => {
      expect(wrapper.findComponent(GlAlert).text()).toBe(
        'An error occurred while loading groups. Please try again.',
      );
    });

    it('emits an error status', () => {
      expect(lastEmittedStatus()).toEqual({ loading: false, count: 0, error: true });
    });
  });

  describe('when the user cannot be found', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockResolvedValue({ data: { user: null } }));
      await waitForPromises();
    });

    it('shows an error alert', () => {
      expect(wrapper.findComponent(GlAlert).text()).toBe(
        'An error occurred while loading groups. Please try again.',
      );
    });

    it('emits an error status', () => {
      expect(lastEmittedStatus()).toEqual({ loading: false, count: 0, error: true });
    });
  });
});
