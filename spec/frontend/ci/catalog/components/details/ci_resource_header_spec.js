import { GlAvatar, GlAvatarLink, GlBadge, GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import CiResourceHeader from '~/ci/catalog/components/details/ci_resource_header.vue';
import CiVerificationBadge from '~/ci/catalog/components/shared/ci_verification_badge.vue';
import ProjectVisibilityIcon from '~/ci/catalog/components/shared/project_visibility_icon.vue';
import TopicBadges from '~/vue_shared/components/topic_badges.vue';
import { catalogSharedDataMock } from '../../mock';

describe('CiResourceHeader', () => {
  let wrapper;

  const resource = { ...catalogSharedDataMock.data.ciCatalogResource };
  const versions = [
    {
      value: 'gid://gitlab/Ci::Catalog::Resources::Version/2',
      text: '1.1.0',
      createdAt: '2025-01-01',
    },
    {
      value: 'gid://gitlab/Ci::Catalog::Resources::Version/1',
      text: '1.0.0',
      createdAt: '2023-01-01',
    },
  ];
  const initialVersionId = 'gid://gitlab/Ci::Catalog::Resources::Version/1';
  const latestVersionName = '1.1.0';

  const defaultProps = {
    isLoadingData: false,
    resource,
    versions,
    initialVersionId,
    latestVersionName,
  };

  const $router = {
    push: jest.fn(),
  };

  const findReportAbuseButton = () => wrapper.findByTestId('report-abuse-button');
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findTopicBadgesComponent = () => wrapper.findComponent(TopicBadges);
  const findVerificationBadge = () => wrapper.findComponent(CiVerificationBadge);
  const findVersionBadge = () => wrapper.findComponent(GlBadge);
  const findVisibilityIcon = () => wrapper.findComponent(ProjectVisibilityIcon);
  const findArchiveBadge = () => wrapper.findByTestId('archive-badge');
  const findVersionDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findVersionButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourceHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        reportAbusePath: '/report/abuse/path',
      },
      mocks: {
        $router,
        $route: {
          query: {},
        },
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the project name and description', () => {
      expect(wrapper.html()).toContain(resource.name);
      expect(wrapper.html()).toContain(resource.description);
    });

    it('renders the project path and name', () => {
      expect(wrapper.html()).toContain(resource.webPath);
      expect(wrapper.html()).toContain(resource.name);
    });

    it('renders the avatar', () => {
      const { id, name } = resource;

      expect(findAvatar().exists()).toBe(true);
      expect(findAvatarLink().exists()).toBe(true);
      expect(findAvatar().props()).toMatchObject({
        entityId: getIdFromGraphQLId(id),
        entityName: name,
      });
    });
  });

  describe('Version badge', () => {
    describe('without a version', () => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, versions: null } } });
      });

      it('does not render', () => {
        expect(findVersionBadge().exists()).toBe(false);
      });
    });

    describe('with a version', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders', () => {
        expect(findVersionBadge().exists()).toBe(true);
      });
    });
  });

  describe('Visibility level', () => {
    describe('as a public project', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render a lock icon', () => {
        expect(findVisibilityIcon().exists()).toBe(false);
      });
    });

    describe('as a private project', () => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, visibilityLevel: 'private' } } });
      });

      it('renders a lock icon', () => {
        expect(findVisibilityIcon().exists()).toBe(true);
      });
    });
  });

  describe('verification badge', () => {
    describe('when the resource is not verified', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render the verification badge', () => {
        expect(findVerificationBadge().exists()).toBe(false);
      });
    });

    describe.each`
      verificationLevel | describeText
      ${'GITLAB'}       | ${'GitLab'}
      ${'PARTNER'}      | ${'partner'}
    `('when the resource is $describeText maintained', ({ verificationLevel }) => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, verificationLevel } } });
      });

      it('renders the verification badge', () => {
        expect(findVerificationBadge().exists()).toBe(true);
      });

      it('displays the correct badge', () => {
        expect(findVerificationBadge().props('verificationLevel')).toBe(verificationLevel);
      });
    });
  });

  describe('project topics', () => {
    describe('when there are no topics', () => {
      it('does not render the topic badges component', () => {
        createComponent();

        expect(findTopicBadgesComponent().exists()).toBe(false);
      });
    });

    describe('when there are topics', () => {
      it('renders the topic badges component', () => {
        const topics = ['vue.js', 'Ruby'];
        createComponent({ props: { resource: { ...resource, topics } } });

        expect(findTopicBadgesComponent().exists()).toBe(true);
        expect(findTopicBadgesComponent().props('topics')).toBe(topics);
      });
    });
  });

  describe('report abuse button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the abuse category selector', () => {
      expect(findReportAbuseButton().exists()).toBe(true);
      expect(findAbuseCategorySelector().exists()).toBe(false);
    });

    it('opens the abuse category drawer', async () => {
      const reportedUrl = window.location.href;
      await findReportAbuseButton().vm.$emit('action');

      expect(findAbuseCategorySelector().exists()).toBe(true);
      expect(findAbuseCategorySelector().props()).toMatchObject({
        showDrawer: true,
        reportedUserId: 1,
        reportedFromUrl: reportedUrl,
      });
    });

    it('closes the abuse category drawer', async () => {
      await findReportAbuseButton().vm.$emit('action');
      expect(findAbuseCategorySelector().exists()).toEqual(true);

      await findAbuseCategorySelector().vm.$emit('close-drawer');
      expect(findAbuseCategorySelector().exists()).toEqual(false);
    });

    describe('when user is not active', () => {
      beforeEach(() => {
        resource.versions.nodes[0].author.state = 'deleted';
        createComponent();
      });

      it('should report with an empty user', async () => {
        const reportedUrl = window.location.href;
        await findReportAbuseButton().vm.$emit('action');

        expect(findAbuseCategorySelector().exists()).toBe(true);
        expect(findAbuseCategorySelector().props()).toMatchObject({
          showDrawer: true,
          reportedUserId: 0,
          reportedFromUrl: reportedUrl,
        });
      });
    });

    describe('archive badge', () => {
      it('renders the archive badge when resource is archived', () => {
        createComponent({ props: { resource: { ...resource, archived: true } } });
        expect(findArchiveBadge().exists()).toBe(true);
      });

      it('does not render the archive badge when resource is not archived', () => {
        createComponent({ props: { resource: { ...resource, archived: false } } });
        expect(findArchiveBadge().exists()).toBe(false);
      });
    });
  });

  describe('version selector dropdown', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the version dropdown with initial version selected', () => {
      expect(findVersionButton().text()).toBe('1.0.0 (2023-01-01)');
    });

    it('passes versions array to the dropdown', () => {
      expect(findVersionDropdown().props('items')).toEqual(versions);
    });

    it('emits version-selected event when a version is selected', async () => {
      await findVersionDropdown().vm.$emit('select', versions[0].value);

      expect(wrapper.emitted('version-selected')).toEqual([['1.1.0']]);
    });

    it('updates the URL query parameter when a version is selected', async () => {
      await findVersionDropdown().vm.$emit('select', versions[0].value);

      expect($router.push).toHaveBeenCalledWith({
        query: { version: '1.1.0' },
      });
    });

    describe('when loading', () => {
      beforeEach(() => {
        createComponent({ props: { isLoadingData: true, versions: [], initialVersionId: null } });
      });

      it('shows "Loading" text in button', () => {
        expect(findVersionButton().text()).toBe('Loading');
      });

      it('shows loading state on button', () => {
        expect(findVersionButton().props('loading')).toBe(true);
      });
    });

    describe('when no versions available', () => {
      beforeEach(() => {
        createComponent({ props: { versions: [], initialVersionId: null } });
      });

      it('shows "No versions available" text', () => {
        expect(findVersionButton().text()).toContain('No versions available');
      });
    });

    describe('when searching versions', () => {
      it('shows loading icon when isSearchingVersions is true', () => {
        createComponent({ props: { isSearchingVersions: true } });

        expect(findVersionDropdown().props('loading')).toBe(true);
        expect(findVersionButton().props('loading')).toBe(true);
      });

      it('emits version-search event', () => {
        createComponent();

        findVersionDropdown().vm.$emit('search', '1.0');

        expect(wrapper.emitted('version-search')).toEqual([['1.0']]);
      });

      it('preserves selected version when versions prop changes to filtered results', async () => {
        createComponent();

        expect(findVersionButton().text()).toBe('1.0.0 (2023-01-01)');

        const filteredVersions = [
          {
            value: 'gid://gitlab/Ci::Catalog::Resources::Version/3',
            text: '2.0.0',
            createdAt: '2026-01-01',
          },
        ];

        await wrapper.setProps({ versions: filteredVersions });

        expect(findVersionButton().text()).toBe('1.0.0 (2023-01-01)');
      });
    });
  });

  describe.each`
    versionId                                           | versionName | isLatest | expectedVariant
    ${'gid://gitlab/Ci::Catalog::Resources::Version/2'} | ${'1.1.0'}  | ${true}  | ${'info'}
    ${'gid://gitlab/Ci::Catalog::Resources::Version/1'} | ${'1.0.0'}  | ${false} | ${'neutral'}
  `('version badge variant', ({ versionId, versionName, isLatest, expectedVariant }) => {
    it(`shows ${expectedVariant} variant when viewing ${isLatest ? 'latest' : 'older'} version`, () => {
      const versionResource = {
        ...resource,
        versions: {
          nodes: [
            {
              id: versionId,
              name: versionName,
              path: '/path',
              createdAt: isLatest ? '2025-01-01' : '2023-01-01',
              author: { id: 1, name: 'author', state: 'active', webUrl: '/user/1' },
            },
          ],
        },
      };
      createComponent({
        props: {
          resource: versionResource,
          initialVersionId: versionId,
        },
      });

      expect(findVersionBadge().props('variant')).toBe(expectedVariant);
    });
  });
});
