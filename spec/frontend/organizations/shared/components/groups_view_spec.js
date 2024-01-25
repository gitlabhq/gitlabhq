import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import { formatGroups } from '~/organizations/shared/utils';
import groupsQuery from '~/organizations/shared/graphql/queries/groups.query.graphql';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { organizationGroups as nodes, pageInfo, pageInfoEmpty } from '~/organizations/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('GroupsView', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    groupsEmptyStateSvgPath: 'illustrations/empty-state/empty-groups-md.svg',
    newGroupPath: '/groups/new',
    organizationGid: 'gid://gitlab/Organizations::Organization/1',
  };

  const defaultPropsData = {
    listItemClass: 'gl-px-5',
  };

  const groups = {
    nodes,
    pageInfo,
  };

  const successHandler = jest.fn().mockResolvedValue({
    data: {
      organization: {
        id: defaultProvide.organizationGid,
        groups,
      },
    },
  });

  const createComponent = ({ handler = successHandler, propsData = {} } = {}) => {
    mockApollo = createMockApollo([[groupsQuery, handler]]);

    wrapper = shallowMountExtended(GroupsView, {
      apolloProvider: mockApollo,
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('when API call is loading', () => {
    it('renders loading icon', () => {
      createComponent();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    describe('when there are no groups', () => {
      const emptyHandler = jest.fn().mockResolvedValue({
        data: {
          organization: {
            id: defaultProvide.organizationGid,
            groups: {
              nodes: [],
              pageInfo: pageInfoEmpty,
            },
          },
        },
      });

      it('renders empty state without buttons by default', async () => {
        createComponent({ handler: emptyHandler });

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
          createComponent({
            handler: emptyHandler,
            propsData: { shouldShowEmptyStateButtons: true },
          });

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
        await waitForPromises();

        expect(wrapper.findComponent(GroupsList).props()).toMatchObject({
          groups: formatGroups(nodes),
          showGroupIcon: true,
          listItemClass: defaultPropsData.listItemClass,
        });
      });
    });
  });

  describe('when API call is not successful', () => {
    const error = new Error();

    beforeEach(() => {
      createComponent({ handler: jest.fn().mockRejectedValue(error) });
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
