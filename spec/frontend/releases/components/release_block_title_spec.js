import { GlLink, GlBadge } from '@gitlab/ui';
import { merge } from 'lodash';
import originalRelease from 'test_fixtures/api/releases/release.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ReleaseBlockTitle from '~/releases/components/release_block_title.vue';

describe('Release block header', () => {
  let wrapper;
  let release;

  const factory = (releaseUpdates = {}) => {
    wrapper = shallowMountExtended(ReleaseBlockTitle, {
      propsData: {
        release: merge({}, release, releaseUpdates),
      },
      stubs: { GlBadge },
    });
  };

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  const findPlainHeader = () => wrapper.findByTestId('release-block-title');
  const findHeaderLink = () => wrapper.findComponent(GlLink);
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('when _links.self is provided', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the title as a link', () => {
      const link = findHeaderLink();

      expect(link.text()).toBe(release.name);
      expect(link.attributes('href')).toBe(release._links.self);
    });

    it('does not show plain header', () => {
      expect(findPlainHeader().exists()).toBe(false);
    });
  });

  describe('when _links.self is missing', () => {
    beforeEach(() => {
      factory({ _links: { self: null } });
    });

    it('renders a plain header', () => {
      expect(findPlainHeader().text()).toBe(release.name);
      expect(findHeaderLink().exists()).toBe(false);
    });
  });

  describe('upcoming release', () => {
    beforeEach(() => {
      factory({ upcomingRelease: true, historicalRelease: false });
    });

    it('shows a badge that the release is upcoming', () => {
      const badge = findBadge();

      expect(badge.text()).toBe('Upcoming Release');
      expect(badge.props('variant')).toBe('warning');
    });
  });

  describe('historical release', () => {
    beforeEach(() => {
      factory({ upcomingRelease: false, historicalRelease: true });
    });

    it('shows a badge that the release is historical', () => {
      const badge = findBadge();

      expect(badge.text()).toBe('Historical release');
      expect(badge.attributes('title')).toBe(
        'This release was created with a date in the past. Evidence collection at the moment of the release is unavailable.',
      );
    });
  });
});
