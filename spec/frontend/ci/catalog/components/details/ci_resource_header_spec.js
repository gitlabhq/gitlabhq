import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
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

  const defaultProps = {
    isLoadingData: false,
    resource,
  };

  const findReportAbuseButton = () => wrapper.findByTestId('report-abuse-button');
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findTopicBadgesComponent = () => wrapper.findComponent(TopicBadges);
  const findVerificationBadge = () => wrapper.findComponent(CiVerificationBadge);
  const findVersionBadge = () => wrapper.findComponent(GlBadge);
  const findVisibilityIcon = () => wrapper.findComponent(ProjectVisibilityIcon);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourceHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        reportAbusePath: '/report/abuse/path',
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
  });
});
