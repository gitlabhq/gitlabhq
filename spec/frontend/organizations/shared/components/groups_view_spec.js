import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import { formatGroups } from '~/organizations/shared/utils';
import resolvers from '~/organizations/shared/graphql/resolvers';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { organizationGroups } from '~/organizations/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);
jest.useFakeTimers();

describe('GroupsView', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    groupsEmptyStateSvgPath: 'illustrations/empty-state/empty-groups-md.svg',
    newGroupPath: '/groups/new',
  };

  const createComponent = ({ mockResolvers = resolvers, propsData = {} } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMountExtended(GroupsView, {
      apolloProvider: mockApollo,
      provide: defaultProvide,
      propsData,
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('when API call is loading', () => {
    beforeEach(() => {
      const mockResolvers = {
        Query: {
          organization: jest.fn().mockReturnValueOnce(new Promise(() => {})),
        },
      };

      createComponent({ mockResolvers });
    });

    it('renders loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    describe('when there are no groups', () => {
      it('renders empty state without buttons by default', async () => {
        const mockResolvers = {
          Query: {
            organization: jest.fn().mockResolvedValueOnce({
              groups: { nodes: [] },
            }),
          },
        };
        createComponent({ mockResolvers });

        jest.runAllTimers();
        await waitForPromises();

        expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
          title: "You don't have any groups yet.",
          description:
            'A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
          svgHeight: 144,
          svgPath: defaultProvide.groupsEmptyStateSvgPath,
          primaryButtonLink: null,
          primaryButtonText: null,
        });
      });

      describe('when `shouldShowEmptyStateButtons` is `true` and `groupsEmptyStateSvgPath` is set', () => {
        it('renders empty state with buttons', async () => {
          const mockResolvers = {
            Query: {
              organization: jest.fn().mockResolvedValueOnce({
                groups: { nodes: [] },
              }),
            },
          };
          createComponent({ mockResolvers, propsData: { shouldShowEmptyStateButtons: true } });

          jest.runAllTimers();
          await waitForPromises();

          expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
            primaryButtonLink: defaultProvide.newGroupPath,
            primaryButtonText: 'New group',
          });
        });
      });
    });

    describe('when there are groups', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders `GroupsList` component and passes correct props', async () => {
        jest.runAllTimers();
        await waitForPromises();

        expect(wrapper.findComponent(GroupsList).props()).toEqual({
          groups: formatGroups(organizationGroups.nodes),
          showGroupIcon: true,
        });
      });
    });
  });

  describe('when API call is not successful', () => {
    const error = new Error();

    beforeEach(() => {
      const mockResolvers = {
        Query: {
          organization: jest.fn().mockRejectedValueOnce(error),
        },
      };

      createComponent({ mockResolvers });
    });

    it('displays error alert', async () => {
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: GroupsView.i18n.errorMessage,
        error,
        captureError: true,
      });
    });
  });
});
