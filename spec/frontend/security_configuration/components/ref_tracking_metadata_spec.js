import { GlBadge, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefTrackingMetadata from '~/security_configuration/components/ref_tracking_metadata.vue';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createTrackedRef } from '../mock_data';

describe('RefTrackingMetadata component', () => {
  let wrapper;

  const createComponent = ({ trackedRef = createTrackedRef() } = {}) => {
    wrapper = shallowMountExtended(RefTrackingMetadata, {
      propsData: {
        trackedRef,
      },
    });
  };

  const findRefName = () => wrapper.findByTestId('ref-name');
  const findDefaultBadge = () => wrapper.findComponent(GlBadge);
  const findProtectedBadge = () => wrapper.findComponent(ProtectedBadge);
  const findRefTypeIcon = () => wrapper.findByTestId('ref-type').findComponent(GlIcon);
  const findRefTypeText = () => wrapper.findByTestId('ref-type').find('span');
  const findCommitIcon = () => wrapper.findByTestId('commit-link').findComponent(GlIcon);
  const findCommitLink = () => wrapper.findByTestId('commit-link').findComponent(GlLink);
  const findCommitTitle = () => wrapper.findByTestId('commit-title');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  describe('rendering ref name and badges', () => {
    it('renders the ref name correctly', () => {
      createComponent();

      expect(findRefName().text()).toBe(createTrackedRef().name);
    });

    it('shows default badge when isDefault is true', () => {
      createComponent({ trackedRef: createTrackedRef({ isDefault: true }) });

      expect(findDefaultBadge().props()).toMatchObject({
        variant: 'info',
      });
    });

    it('hides default badge when isDefault is false', () => {
      createComponent({ trackedRef: createTrackedRef({ isDefault: false }) });

      expect(findDefaultBadge().exists()).toBe(false);
    });

    it('shows protected badge when isProtected is true', () => {
      createComponent({ trackedRef: createTrackedRef({ isProtected: true }) });

      expect(findProtectedBadge().exists()).toBe(true);
    });

    it('hides protected badge when isProtected is false', () => {
      createComponent({ trackedRef: createTrackedRef({ isProtected: false }) });

      expect(findProtectedBadge().exists()).toBe(false);
    });
  });

  describe('rendering ref type information', () => {
    it('displays branch icon and text for branches', () => {
      createComponent({ trackedRef: createTrackedRef({ refType: 'HEAD' }) });

      expect(findRefTypeIcon().props('name')).toBe('branch');
      expect(findRefTypeText().text()).toBe('branch');
    });

    it('displays tag icon and text for tags', () => {
      createComponent({ trackedRef: createTrackedRef({ refType: 'TAG' }) });

      expect(findRefTypeIcon().props('name')).toBe('tag');
      expect(findRefTypeText().text()).toBe('tag');
    });

    it('sets correct icon size', () => {
      createComponent({ trackedRef: createTrackedRef({ refType: 'HEAD' }) });

      expect(findRefTypeIcon().props('size')).toBe(12);
    });
  });

  describe('rendering commit information', () => {
    beforeEach(() => {
      createComponent({ trackedRef: createTrackedRef({ refType: 'HEAD' }) });
    });

    it('displays commit icon with correct size', () => {
      expect(findCommitIcon().props('name')).toBe('commit');
      expect(findCommitIcon().props('size')).toBe(12);
    });

    it('renders commit link with correct href and text', () => {
      expect(findCommitLink().attributes('href')).toBe(createTrackedRef().commit.webPath);
      expect(findCommitLink().text()).toBe(createTrackedRef().commit.shortId);
    });

    it('displays commit title', () => {
      expect(findCommitTitle().text()).toBe(createTrackedRef().commit.title);
    });
  });

  describe('rendering timestamp', () => {
    it('displays TimeAgoTooltip with correct time', () => {
      createComponent();

      expect(findTimeAgoTooltip().props('time')).toBe(createTrackedRef().commit.authoredDate);
    });
  });
});
