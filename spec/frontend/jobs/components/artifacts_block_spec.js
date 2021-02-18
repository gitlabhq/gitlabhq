import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import ArtifactsBlock from '~/jobs/components/artifacts_block.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';

describe('Artifacts block', () => {
  let wrapper;

  const createWrapper = (propsData) =>
    mount(ArtifactsBlock, {
      propsData: {
        helpUrl: 'help-url',
        ...propsData,
      },
    });

  const findArtifactRemoveElt = () => wrapper.find('[data-testid="artifacts-remove-timeline"]');
  const findJobLockedElt = () => wrapper.find('[data-testid="job-locked-message"]');
  const findKeepBtn = () => wrapper.find('[data-testid="keep-artifacts"]');
  const findDownloadBtn = () => wrapper.find('[data-testid="download-artifacts"]');
  const findBrowseBtn = () => wrapper.find('[data-testid="browse-artifacts"]');

  const expireAt = '2018-08-14T09:38:49.157Z';
  const timeago = getTimeago();
  const formattedDate = timeago.format(expireAt);
  const lockedText =
    'These artifacts are the latest. They will not be deleted (even if expired) until newer artifacts are available.';

  const expiredArtifact = {
    expire_at: expireAt,
    expired: true,
    locked: false,
  };

  const nonExpiredArtifact = {
    download_path: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/download',
    browse_path: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/browse',
    keep_path: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/keep',
    expire_at: expireAt,
    expired: false,
    locked: false,
  };

  const lockedExpiredArtifact = {
    ...expiredArtifact,
    download_path: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/download',
    browse_path: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/browse',
    expired: true,
    locked: true,
  };

  const lockedNonExpiredArtifact = {
    ...nonExpiredArtifact,
    keep_path: undefined,
    locked: true,
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with expired artifacts that are not locked', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        artifact: expiredArtifact,
      });
    });

    it('renders expired artifact date and info', () => {
      expect(trimText(findArtifactRemoveElt().text())).toBe(
        `The artifacts were removed ${formattedDate}`,
      );

      expect(
        findArtifactRemoveElt()
          .find('[data-testid="artifact-expired-help-link"]')
          .attributes('href'),
      ).toBe('help-url');
    });

    it('does not show the keep button', () => {
      expect(findKeepBtn().exists()).toBe(false);
    });

    it('does not show the download button', () => {
      expect(findDownloadBtn().exists()).toBe(false);
    });

    it('does not show the browse button', () => {
      expect(findBrowseBtn().exists()).toBe(false);
    });
  });

  describe('with artifacts that will expire', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        artifact: nonExpiredArtifact,
      });
    });

    it('renders will expire artifact date and info', () => {
      expect(trimText(findArtifactRemoveElt().text())).toBe(
        `The artifacts will be removed ${formattedDate}`,
      );

      expect(
        findArtifactRemoveElt()
          .find('[data-testid="artifact-expired-help-link"]')
          .attributes('href'),
      ).toBe('help-url');
    });

    it('renders the keep button', () => {
      expect(findKeepBtn().exists()).toBe(true);
    });

    it('renders the download button', () => {
      expect(findDownloadBtn().exists()).toBe(true);
    });

    it('renders the browse button', () => {
      expect(findBrowseBtn().exists()).toBe(true);
    });
  });

  describe('with expired locked artifacts', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        artifact: lockedExpiredArtifact,
      });
    });

    it('renders the information that the artefacts are locked', () => {
      expect(findArtifactRemoveElt().exists()).toBe(false);
      expect(trimText(findJobLockedElt().text())).toBe(lockedText);
    });

    it('does not render the keep button', () => {
      expect(findKeepBtn().exists()).toBe(false);
    });

    it('renders the download button', () => {
      expect(findDownloadBtn().exists()).toBe(true);
    });

    it('renders the browse button', () => {
      expect(findBrowseBtn().exists()).toBe(true);
    });
  });

  describe('with non expired locked artifacts', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        artifact: lockedNonExpiredArtifact,
      });
    });

    it('renders the information that the artefacts are locked', () => {
      expect(findArtifactRemoveElt().exists()).toBe(false);
      expect(trimText(findJobLockedElt().text())).toBe(lockedText);
    });

    it('does not render the keep button', () => {
      expect(findKeepBtn().exists()).toBe(false);
    });

    it('renders the download button', () => {
      expect(findDownloadBtn().exists()).toBe(true);
    });

    it('renders the browse button', () => {
      expect(findBrowseBtn().exists()).toBe(true);
    });
  });
});
