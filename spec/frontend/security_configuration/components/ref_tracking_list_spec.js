import { GlBadge, GlButton, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RefTrackingList, {
  MAX_TRACKED_REFS,
} from '~/security_configuration/components/ref_tracking_list.vue';
import RefTrackingListItem from '~/security_configuration/components/ref_tracking_list_item.vue';
import securityTrackedRefsQuery from '~/security_configuration/graphql/security_tracked_refs.query.graphql';
import { createTrackedRef } from '../mock_data';

Vue.use(VueApollo);

const mockTrackedRefs = [
  createTrackedRef({
    id: 'gid://gitlab/TrackedRef/1',
    name: 'Main',
    refType: 'HEAD',
    isDefault: true,
    isProtected: true,
    vulnerabilitiesCount: 258,
    commit: {
      sha: 'df210850abc123',
      shortId: 'df21085',
      title: 'Apply 1 suggestion(s) to 1 file(s)',
      authoredDate: '2024-10-17T09:59:00Z',
      webPath: '/project/-/commit/df21085',
    },
  }),
  createTrackedRef({
    id: 'gid://gitlab/TrackedRef/2',
    name: 'v18.1.4-33',
    refType: 'TAG',
    commit: {
      sha: '693bb5e6abc456',
      shortId: '693bb5e6',
      title: 'Update VERSION files',
      authoredDate: '2024-10-15T14:30:00Z',
      webPath: '/project/-/commit/693bb5e6',
    },
  }),
];

const mockTrackedRefsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      __typename: 'Project',
      securityTrackedRefs: mockTrackedRefs,
    },
  },
};

describe('RefTrackingList component', () => {
  let wrapper;

  const createApolloProvider = ({
    queryHandler = jest.fn().mockResolvedValue(mockTrackedRefsResponse),
  } = {}) => createMockApollo([[securityTrackedRefsQuery, queryHandler]]);

  const createComponent = ({ queryHandler } = {}) => {
    wrapper = shallowMountExtended(RefTrackingList, {
      apolloProvider: createApolloProvider({ queryHandler }),
      provide: {
        projectFullPath: 'namespace/project',
      },
      stubs: {
        GlCard,
      },
    });
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findTitle = () => wrapper.findByTestId('tracked-refs-title');
  const findCountBadge = () => wrapper.findByTestId('tracked-refs-header').findComponent(GlBadge);
  const findTrackNewRefButton = () =>
    wrapper.findByTestId('tracked-refs-header').findComponent(GlButton);
  const findRefList = () => wrapper.find('ul[data-testid="tracked-refs-list"]');
  const findRefListItems = () => wrapper.findAllComponents(RefTrackingListItem);
  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);

  describe('rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders a GlCard', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders header with title', () => {
      expect(findTitle().text()).toBe('Currently tracked refs');
    });

    it('renders count badge with current and max values', () => {
      expect(findCountBadge().text()).toBe(`${mockTrackedRefs.length}/${MAX_TRACKED_REFS}`);
    });

    it('renders Track new ref button', () => {
      expect(findTrackNewRefButton().text()).toBe('Track new ref');
    });

    it('renders unordered list for refs', () => {
      expect(findRefList().exists()).toBe(true);
    });
  });

  describe('ref list items', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders correct number of RefTrackingListItem components', () => {
      expect(findRefListItems()).toHaveLength(mockTrackedRefs.length);
    });

    it.each(mockTrackedRefs)(
      'passes correct data to RefTrackingListItem for ref "$name"',
      (trackedRef) => {
        const index = mockTrackedRefs.indexOf(trackedRef);

        expect(findRefListItems().at(index).props('trackedRef')).toEqual(trackedRef);
      },
    );
  });

  describe('loading state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a placeholder within the count badge while loading', () => {
      expect(findCountBadge().text()).toBe(`-/${MAX_TRACKED_REFS}`);
    });

    it('shows skeleton loader while loading', () => {
      expect(findSkeletonLoaders()).toHaveLength(4);
      expect(findRefList().exists()).toBe(false);
    });

    it('hides skeleton loader after data loads', async () => {
      await waitForPromises();

      expect(findSkeletonLoaders()).toHaveLength(0);
      expect(findRefList().exists()).toBe(true);
      expect(findRefListItems()).toHaveLength(mockTrackedRefs.length);
    });
  });
});
