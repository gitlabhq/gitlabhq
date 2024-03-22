import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import CiResourceHeader from '~/ci/catalog/components/details/ci_resource_header.vue';
import CiResourceAbout from '~/ci/catalog/components/details/ci_resource_about.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { catalogSharedDataMock, catalogAdditionalDetailsMock } from '../../mock';

describe('CiResourceHeader', () => {
  let wrapper;

  const resource = { ...catalogSharedDataMock.data.ciCatalogResource };
  const resourceAdditionalData = { ...catalogAdditionalDetailsMock.data.ciCatalogResource };

  const defaultProps = {
    openIssuesCount: resourceAdditionalData.openIssuesCount,
    openMergeRequestsCount: resourceAdditionalData.openMergeRequestsCount,
    isLoadingDetails: false,
    isLoadingSharedData: false,
    resource,
  };

  const findAboutComponent = () => wrapper.findComponent(CiResourceAbout);
  const findReportAbuseButton = () => wrapper.findByTestId('report-abuse-button');
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findVersionBadge = () => wrapper.findComponent(GlBadge);
  const findPipelineStatusBadge = () => wrapper.findComponent(CiIcon);

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

    it('renders the catalog about section and passes props', () => {
      expect(findAboutComponent().exists()).toBe(true);
      expect(findAboutComponent().props()).toEqual({
        isLoadingDetails: false,
        isLoadingSharedData: false,
        openIssuesCount: defaultProps.openIssuesCount,
        openMergeRequestsCount: defaultProps.openMergeRequestsCount,
        latestVersion: resource.versions.nodes[0],
        webPath: resource.webPath,
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

  describe('when the project has a release', () => {
    const pipelineStatus = {
      detailsPath: 'path/to/pipeline',
      icon: 'status_success',
      text: 'passed',
      group: 'success',
    };

    describe.each`
      hasPipelineBadge | describeText | testText             | status
      ${true}          | ${'is'}      | ${'renders'}         | ${pipelineStatus}
      ${false}         | ${'is not'}  | ${'does not render'} | ${{}}
    `('and there $describeText a pipeline', ({ hasPipelineBadge, testText, status }) => {
      beforeEach(() => {
        createComponent({
          props: {
            pipelineStatus: status,
            latestVersion: { name: '1.0.0', path: 'path/to/release' },
          },
        });
      });

      it('renders the version badge', () => {
        expect(findVersionBadge().exists()).toBe(true);
      });

      it(`${testText} the pipeline status badge`, () => {
        expect(findPipelineStatusBadge().exists()).toBe(hasPipelineBadge);
        if (hasPipelineBadge) {
          expect(findPipelineStatusBadge().props()).toEqual({
            showStatusText: true,
            status: pipelineStatus,
            showTooltip: true,
            useLink: true,
          });
        }
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
