import { GlLink, GlBadge } from '@gitlab/ui';
import { merge } from 'lodash';
import originalRelease from 'test_fixtures/api/releases/release.json';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import CiCdCatalogWrapper from '~/releases/components/ci_cd_catalog_wrapper.vue';
import ReleaseBlockTitle from '~/releases/components/release_block_title.vue';

describe('ReleaseBlockTitle', () => {
  let wrapper;
  let release;

  const detailsPagePath = '/path';

  const createComponent = ({ isCatalogRelease = false, releaseUpdates = {} } = {}) => {
    wrapper = shallowMountExtended(ReleaseBlockTitle, {
      propsData: {
        release: merge({}, release, releaseUpdates),
      },
      stubs: {
        CiCdCatalogWrapper: {
          ...stubComponent(CiCdCatalogWrapper),
          render() {
            return this.$scopedSlots.default({
              detailsPagePath,
              isCatalogRelease,
            });
          },
        },
        GlBadge,
      },
    });
  };

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findCatalogBadge = () => wrapper.findByTestId('catalog-badge');
  const findHeaderLink = () => wrapper.findComponent(GlLink);
  const findPlainHeader = () => wrapper.findByTestId('release-block-title');

  describe('when _links.self is provided', () => {
    beforeEach(() => {
      createComponent();
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
      createComponent({ releaseUpdates: { _links: { self: null } } });
    });

    it('renders a plain header', () => {
      expect(findPlainHeader().text()).toBe(release.name);
      expect(findHeaderLink().exists()).toBe(false);
    });
  });

  describe('upcoming release', () => {
    beforeEach(() => {
      createComponent({ releaseUpdates: { upcomingRelease: true, historicalRelease: false } });
    });

    it('shows a badge that the release is upcoming', () => {
      const badge = findBadge();

      expect(badge.text()).toBe('Upcoming Release');
      expect(badge.props('variant')).toBe('warning');
    });
  });

  describe('historical release', () => {
    beforeEach(() => {
      createComponent({ releaseUpdates: { upcomingRelease: false, historicalRelease: true } });
    });

    it('shows a badge that the release is historical', () => {
      const badge = findBadge();

      expect(badge.text()).toBe('Historical release');
      expect(badge.attributes('title')).toBe(
        'This release was created with a date in the past. Evidence collection at the moment of the release is unavailable.',
      );
    });
  });

  describe('ci/cd catalog badge', () => {
    describe('when the release is not a catalog release', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render a catalog badge', () => {
        expect(findCatalogBadge().exists()).toBe(false);
      });
    });

    describe('when the release is a catalog release', () => {
      beforeEach(() => {
        createComponent({ isCatalogRelease: true });
      });

      it('renders a catalog badge', () => {
        expect(findCatalogBadge().exists()).toBe(true);
      });

      it('assigns the correct href to the badge', () => {
        expect(findCatalogBadge().attributes('href')).toBe(detailsPagePath);
      });
    });
  });
});
