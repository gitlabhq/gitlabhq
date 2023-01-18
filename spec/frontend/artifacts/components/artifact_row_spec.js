import { GlBadge, GlButton, GlFriendlyWrap } from '@gitlab/ui';
import mockGetJobArtifactsResponse from 'test_fixtures/graphql/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ArtifactRow from '~/artifacts/components/artifact_row.vue';

describe('ArtifactRow component', () => {
  let wrapper;

  const artifact = mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes[0];

  const findName = () => wrapper.findByTestId('job-artifact-row-name');
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findSize = () => wrapper.findByTestId('job-artifact-row-size');
  const findDownloadButton = () => wrapper.findByTestId('job-artifact-row-download-button');
  const findDeleteButton = () => wrapper.findByTestId('job-artifact-row-delete-button');

  const createComponent = ({ canDestroyArtifacts = true } = {}) => {
    wrapper = shallowMountExtended(ArtifactRow, {
      propsData: {
        artifact,
        isLoading: false,
        isLastRow: false,
      },
      provide: { canDestroyArtifacts },
      stubs: { GlBadge, GlButton, GlFriendlyWrap },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('artifact details', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('displays the artifact name and type', () => {
      expect(findName().text()).toContain(artifact.name);
      expect(findBadge().text()).toBe(artifact.fileType.toLowerCase());
    });

    it('displays the artifact size', () => {
      expect(findSize().text()).toBe(numberToHumanSize(artifact.size));
    });

    it('displays the download button as a link to the download path', () => {
      expect(findDownloadButton().attributes('href')).toBe(artifact.downloadPath);
    });
  });

  describe('delete button', () => {
    it('does not show when user does not have permission', () => {
      createComponent({ canDestroyArtifacts: false });

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('shows when user has permission', () => {
      createComponent();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('emits the delete event when clicked', async () => {
      createComponent();

      expect(wrapper.emitted('delete')).toBeUndefined();

      findDeleteButton().trigger('click');
      await waitForPromises();

      expect(wrapper.emitted('delete')).toBeDefined();
    });
  });
});
