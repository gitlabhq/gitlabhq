import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceHeader from '~/ci/catalog/components/details/ci_resource_header.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiResourceAbout from '~/ci/catalog/components/details/ci_resource_about.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
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
        latestVersion: resource.latestVersion,
        webPath: resource.webPath,
      });
    });
  });

  describe('Version badge', () => {
    describe('without a version', () => {
      beforeEach(() => {
        createComponent({ props: { resource: { ...resource, latestVersion: null } } });
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
            latestVersion: { tagName: '1.0.0', tagPath: 'path/to/release' },
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
});
