import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ReleaseBlockHeader from '~/releases/components/release_block_header.vue';
import { BACK_URL_PARAM } from '~/releases/constants';

const originalRelease = getJSONFixture('api/releases/release.json');

describe('Release block header', () => {
  let wrapper;
  let release;

  const factory = (releaseUpdates = {}) => {
    wrapper = shallowMount(ReleaseBlockHeader, {
      propsData: {
        release: merge({}, release, releaseUpdates),
      },
    });
  };

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeader = () => wrapper.find('h2');
  const findHeaderLink = () => findHeader().find(GlLink);
  const findEditButton = () => wrapper.find('.js-edit-button');

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
      Object.defineProperty(window, 'location', {
        writable: true,
        value: {
          href: currentUrl,
        },
      });

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
});
