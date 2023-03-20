import { GlLink, GlBadge } from '@gitlab/ui';
import { merge } from 'lodash';
import originalRelease from 'test_fixtures/api/releases/release.json';
import setWindowLocation from 'helpers/set_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ReleaseBlockHeader from '~/releases/components/release_block_header.vue';
import { BACK_URL_PARAM } from '~/releases/constants';

describe('Release block header', () => {
  let wrapper;
  let release;

  const factory = (releaseUpdates = {}) => {
    wrapper = shallowMountExtended(ReleaseBlockHeader, {
      propsData: {
        release: merge({}, release, releaseUpdates),
      },
      stubs: { GlBadge },
    });
  };

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  const findHeader = () => wrapper.find('h2');
  const findHeaderLink = () => findHeader().findComponent(GlLink);
  const findEditButton = () => wrapper.find('.js-edit-button');
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
  });

  describe('when _links.self is missing', () => {
    beforeEach(() => {
      factory({ _links: { self: null } });
    });

    it('renders the title as text', () => {
      expect(findHeader().text()).toContain(release.name);
      expect(findHeaderLink().exists()).toBe(false);
    });
  });

  describe('when _links.edit_url is provided', () => {
    const currentUrl = 'https://example.gitlab.com/path';

    beforeEach(() => {
      setWindowLocation(currentUrl);

      factory();
    });

    it('renders an edit button', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('renders the edit button with the correct href', () => {
      const expectedQueryParam = `${BACK_URL_PARAM}=${encodeURIComponent(currentUrl)}`;
      const expectedUrl = `${release._links.editUrl}?${expectedQueryParam}`;
      expect(findEditButton().attributes().href).toBe(expectedUrl);
    });
  });

  describe('when _links.edit is missing', () => {
    beforeEach(() => {
      factory({ _links: { editUrl: null } });
    });

    it('does not render an edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('upcoming release', () => {
    beforeEach(() => {
      factory({ upcomingRelease: true, historicalRelease: false });
    });

    it('shows a badge that the release is upcoming', () => {
      const badge = findBadge();

      expect(badge.text()).toBe(__('Upcoming Release'));
      expect(badge.props('variant')).toBe('warning');
    });
  });

  describe('historical release', () => {
    beforeEach(() => {
      factory({ upcomingRelease: false, historicalRelease: true });
    });

    it('shows a badge that the release is historical', () => {
      const badge = findBadge();

      expect(badge.text()).toBe(__('Historical release'));
      expect(badge.attributes('title')).toBe(
        __(
          'This release was created with a date in the past. Evidence collection at the moment of the release is unavailable.',
        ),
      );
    });
  });
});
